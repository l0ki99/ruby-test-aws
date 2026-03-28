# frozen_string_literal: true

class MigrationsController < ApplicationController
  def execute
    unless ActiveSupport::SecurityUtils.secure_compare(
      request.headers['X-Migrate-Token'].to_s,
      ENV['MIGRATE_SECRET'].to_s
    )
      return render json: { error: 'Forbidden' }, status: :forbidden
    end

    ActiveRecord::Tasks::DatabaseTasks.load_schema_current
    migrations_applied = ActiveRecord::SchemaMigration.count

    load(Rails.root.join('db/seeds.rb'))

    render json: {
      status: 'ok',
      migrations_applied:,
      users_seeded: User.count,
      posts_seeded: Post.count,
      comments_seeded: Comment.count
    }
  rescue => e
    render json: { status: 'error', error: e.message }, status: :internal_server_error
  end
end
