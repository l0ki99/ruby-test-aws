require 'json'
require 'base64'
require 'stringio'

ENV['RAILS_ENV']           ||= 'production'
ENV['RAILS_LOG_TO_STDOUT'] ||= '1'

require_relative 'config/environment'

$rack_app = Rails.application

def handler(event:, context:)
  method  = event.dig('requestContext', 'http', 'method') || 'GET'
  path    = event['rawPath'] || '/'
  query   = event['rawQueryString'] || ''
  headers = event['headers'] || {}
  body    = event['body'] || ''
  body    = Base64.decode64(body) if event['isBase64Encoded']

  rack_env = {
    'REQUEST_METHOD'    => method.upcase,
    'PATH_INFO'         => path,
    'QUERY_STRING'      => query,
    'SERVER_NAME'       => headers['host'] || 'lambda',
    'SERVER_PORT'       => '443',
    'CONTENT_TYPE'      => headers['content-type'] || headers['Content-Type'] || '',
    'CONTENT_LENGTH'    => body.bytesize.to_s,
    'rack.input'        => StringIO.new(body),
    'rack.url_scheme'   => 'https',
    'rack.errors'       => $stderr,
    'rack.multithread'  => true,
    'rack.multiprocess' => false,
    'rack.run_once'     => false,
  }

  headers.each do |k, v|
    key = k.upcase.tr('-', '_')
    next if key == 'CONTENT_TYPE' || key == 'CONTENT_LENGTH'
    rack_env["HTTP_#{key}"] = v
  end

  status, response_headers, response = $rack_app.call(rack_env)

  body_parts = []
  response.each { |part| body_parts << part }
  response.close if response.respond_to?(:close)

  {
    statusCode: status,
    headers:    response_headers.transform_values { |v| Array(v).join(', ') },
    body:       body_parts.join,
  }
end
