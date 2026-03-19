import {useQuery} from '@apollo/client';
import {
  Card,
  CardContent,
  CardMedia,
  CircularProgress,
  Container,
  Grid,
  Paper,
  Stack,
  Typography,
} from '@mui/material';
import {JobberLogoSVG} from './assets/JobberLogo.svg';
import RubyLogo from './assets/RubyLogo.png';
import TanstackLogo from './assets/TanstackLogo.png';
import {ReactLogo} from './assets/ReactLogo.svg';
import {RailsLogo} from './assets/RailsLogo.svg';
import {GraphQLLogo} from './assets/GraphQLLogo.svg';
import {ViteLogo} from './assets/ViteLogo.svg';
import MaterialUILogo from './assets/MaterialUILogo.png';
import {ApolloLogo} from './assets/ApolloLogo.svg';
import {useEffect} from 'react';
import {GET_DATA} from './queries/get_posts';

function App() {
  const {data, loading, error} = useQuery(GET_DATA);

  useEffect(() => {
    const checkForViewCount = async () => {
      const viewCountMessage =
        'View count not available. If you are not building the backend L2+ assessment, you can ignore this message.';
      try {
        const response = await fetch('http://localhost:8090/viewcount');
        if (response.ok) {
          const data = await response.text();
          console.log(data);
        } else {
          console.info(viewCountMessage);
        }
      } catch (e) {
        console.info(viewCountMessage, e);
      }
    };
    checkForViewCount();
  }, []);

  const techStack = [
    {logo: ReactLogo, title: 'React', url: 'https://reactjs.org/'},
    {logo: RailsLogo, title: 'Rails', url: 'https://rubyonrails.org/'},
    {logo: GraphQLLogo, title: 'GraphQL', url: 'https://graphql.org/'},
    {logo: MaterialUILogo, title: 'Material UI', url: 'https://mui.com/'},
    {logo: TanstackLogo, title: 'Tanstack', url: 'https://tanstack.com/'},
    {logo: ViteLogo, title: 'Vite', url: 'https://vitejs.dev/'},
    {logo: RubyLogo, title: 'Ruby', url: 'https://www.ruby-lang.org/en/'},
    {
      logo: ApolloLogo,
      title: 'Apollo',
      url: 'https://www.apollographql.com/',
    },
  ];
  return (
    <Container maxWidth="md">
      <Paper>
        <Stack padding={2}>
          <Stack padding={2}>
            <JobberLogoSVG />
            <Typography marginTop={2} marginBottom={1} variant={'h4'}>
              Take-Home Assessment
            </Typography>
          </Stack>
          <Typography marginLeft={2} variant={'h5'}>
            Starting from a working app
          </Typography>
          <Typography padding={2}>
            This repository already contains a working frontend+backend
            application. You shouldn't need to modify any of the underlying
            system files to complete this assessment.
          </Typography>
          <Typography paddingX={2}>
            That said, if you have ideas on how you would improve this system
            architecture beyond this basic boilerplate, we'd love to hear them!
            Feel free to clean-up/re-organize anything that you think is
            unnecessary or could be improved.
          </Typography>

          <Typography marginLeft={2} marginTop={3} variant={'h5'}>
            Tech Stack
          </Typography>
          <style>
            {`
           
        .logo, .logo svg {
        width:40px !important;
        height:40px;
        }
        .logourl {
        text-decoration:none;
        }
        `}
          </style>
          <Grid container spacing={2} padding={2}>
            {techStack.map((tech, index) => (
              <Grid item xs={6} sm={4} md={3} key={index}>
                <a href={tech.url} target="_blank" className="logourl">
                  <Card
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      paddingTop: '16px',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}>
                    {typeof tech.logo === 'string' ? (
                      <CardMedia
                        component="img"
                        image={tech.logo}
                        className="logo"
                        alt={`${tech.title} logo`}
                      />
                    ) : (
                      <div className="logo">
                        <tech.logo></tech.logo>
                      </div>
                    )}
                    <CardContent>
                      <Typography component="div">{tech.title}</Typography>
                    </CardContent>
                  </Card>
                </a>
              </Grid>
            ))}
          </Grid>
          <Typography paddingX={2}>
            All of these are already installed and in use, and the steps in the
            README should have already set up and started all of them.
          </Typography>
          <Typography marginLeft={2} variant={'h5'} marginTop={4}>
            Expectations
          </Typography>
          <Typography padding={2}>
            We expect you to write clean, readable code that is easy to
            understand. We expect you to use reasonable variable names. We
            expect you to write tests for your code that shows it working as
            intended. We expect your code to work. We expect your code to be DRY
            where appropriate. We will talk about any of the above during the
            functional portion of the interview. Do what you can inside of the 3
            hour time frame.
          </Typography>
          <Typography marginLeft={2} variant={'h5'} marginTop={4}>
            L2 and Above
          </Typography>
          <Typography padding={2}>
            We expect you to use good method names. We expect you to think about
            edge cases and how to handle them, but not necessarily code every
            single case.
          </Typography>
          <Typography marginLeft={2} variant={'h5'} marginTop={4}>
            L3 and Above
          </Typography>
          <Typography padding={2}>
            We expect your code to be self documenting. Where it's not obvious
            via self-documentation, we expect you to add comments. We expect
            your code to be performant. We expect you to consider extensibility
            and maintenace with your solution. We expect you to leverage unit +
            integration tests, and use a testing framework (already installed).
          </Typography>
          <Typography marginLeft={2} variant={'h5'} marginTop={4}>
            Front-End Specific Expectations
          </Typography>
          <Typography padding={2}>
            We expect your component names to convey a purpose. We expect your
            components to have reasonable variable names. We expect your
            front-end code is not one giant component. We expect you to re-use
            styling when applicable. We expect your view-layer components to be
            decoupled from the back-end (portable). We expect the coded solution
            to look as good or better than the mockups.
          </Typography>
          <Typography paddingX={2}>
            The basic frontend challenges here should be doable without needing
            <code> useState </code> or <code> useEffect </code> within React.
            Apollo Client and Tanstack Router (<code>useSearch</code>,{' '}
            <code>useNavigate</code>) should be enough for any state management
            you need to do. If you do end up using other hooks, include
            documentation about how and why.
          </Typography>
          <Typography margin={2} marginTop={4} variant={'h5'}>
            Frontend Tests
          </Typography>
          <Typography paddingX={2}>
            We expect you to add new tests for any frontend changes you make.
            There are some basic vitest tests in the frontend to get you
            started.
          </Typography>
          <Typography padding={2}>
            You can run the frontend tests with:
          </Typography>
          <Typography padding={2}>
            <code>`cd frontend/ && npm test`</code>
          </Typography>
          <Typography marginLeft={2} marginTop={4} variant={'h5'}>
            Backend Tests
          </Typography>
          <Typography padding={2}>
            We expect you to add new tests for any backend changes you make.
            There are some basic rails tests in the backend folder to get you
            started.
          </Typography>
          <Typography padding={2}>
            You can run the backend tests with:
          </Typography>
          <Typography padding={2}>
            <code>`cd backend/ && bundle exec rails test`</code>
          </Typography>
        </Stack>
      </Paper>

      <Paper>
        <Stack padding={2} marginY={2}>
          {!error && (
            <>
              <Typography variant={'h4'}>
                Post count: {loading && <CircularProgress />}{' '}
                {data?.posts.length}
              </Typography>
              <Typography>
                If you've followed all the steps in the README, there should be
                2 posts in the database before you do anything else. If this is
                showing 0, then double check that all the steps ran correctly,
                including the <code>db:seed</code> step!
              </Typography>
              <Typography>
                You can use this section as a starting point for your
                submission.
              </Typography>
            </>
          )}
          {error && (
            <Typography>
              Something went wrong loading the post data. Is rails running (
              <code>rails s</code> from the <code>backend</code> folder)?{' '}
              {error.message}
            </Typography>
          )}
        </Stack>
      </Paper>

      <Stack marginY={2}>
        <Paper>
          <Stack margin={2}>
            <Typography variant="h6" marginBottom={1}>
              Hints
            </Typography>
            <Typography marginBottom={1}>
              If you're still a little unsure of how to proceed, here's some
              things you can do to get started:
            </Typography>
            <Typography component="ul" marginBottom={2}>
              <Typography component={'li'} marginBottom={2}>
                Familiarize yourself with the code that already exists in the
                repo, and try making changes to see if they show up. Edit this
                page as much as you want!
              </Typography>
              <Typography component={'li'} marginBottom={2}>
                If you're more familiar with a different UI framework, and know
                how to swap it out, go for it. We picked Material UI for this
                demo because it's popular, but we actually use our open-source
                design system + component library at Jobber.
              </Typography>
              <Typography component={'li'} marginBottom={2}>
                We're looking for clean, maintainable code that is easy to
                understand. We're not looking for the most optimized solution
                (at the expense of readability), but we do want to see that
                you're thinking about how to make your code performant.
              </Typography>
              <Typography component={'li'} marginBottom={2}>
                Make sure to write tests! We want to see how you approach
                testing your code and how you think about edge cases. It's okay
                to not test everything, but we want to see that you understand
                the importance of testing and where you decide to draw the line
                at too much testing.
              </Typography>
            </Typography>
          </Stack>
        </Paper>
      </Stack>
    </Container>
  );
}

export default App;
