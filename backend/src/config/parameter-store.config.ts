import { SSMClient, GetParametersCommand } from '@aws-sdk/client-ssm';

const client = new SSMClient({ region: process.env.AWS_REGION || 'us-east-1' });

export async function loadParametersFromSSM(): Promise<boolean> {
  // Only load from SSM in production or if explicitly enabled
  if (process.env.NODE_ENV !== 'production' && !process.env.USE_SSM) {
    console.log('ℹ️  Skipping SSM parameter loading (not in production mode)');
    return true;
  }

  try {
    console.log('🔄 Loading parameters from AWS Systems Manager...');
    
    const command = new GetParametersCommand({
      Names: [
        '/streamsync/prod/database/host',
        '/streamsync/prod/database/port',
        '/streamsync/prod/database/user',
        '/streamsync/prod/database/password',
        '/streamsync/prod/database/name',
        '/streamsync/prod/jwt/secret',
        '/streamsync/prod/youtube/api-key',
        '/streamsync/prod/firebase/project-id',
        '/streamsync/prod/firebase/client-email',
        '/streamsync/prod/firebase/private-key',
      ],
      WithDecryption: true, // Decrypt SecureString parameters
    });

    const response = await client.send(command);
    
    if (!response.Parameters || response.Parameters.length === 0) {
      console.error('❌ No parameters found in SSM');
      return false;
    }

    const params: Record<string, string> = {};

    response.Parameters.forEach((param) => {
      const key = param.Name?.split('/').pop();
      if (key && param.Value) {
        params[key] = param.Value;
      }
    });

    // Map SSM parameters to environment variables
    if (params['host']) process.env.DATABASE_HOST = params['host'];
    if (params['port']) process.env.DATABASE_PORT = params['port'];
    if (params['user']) process.env.DATABASE_USER = params['user'];
    if (params['password']) process.env.DATABASE_PASSWORD = params['password'];
    if (params['name']) process.env.DATABASE_NAME = params['name'];
    if (params['secret']) process.env.JWT_SECRET = params['secret'];
    if (params['api-key']) process.env.YOUTUBE_API_KEY = params['api-key'];
    if (params['project-id']) process.env.FIREBASE_PROJECT_ID = params['project-id'];
    if (params['client-email']) process.env.FIREBASE_CLIENT_EMAIL = params['client-email'];
    if (params['private-key']) process.env.FIREBASE_PRIVATE_KEY = params['private-key'];

    console.log('✅ Successfully loaded', response.Parameters.length, 'parameters from SSM');
    console.log('📊 Database host:', process.env.DATABASE_HOST);
    
    // Report any missing parameters
    if (response.InvalidParameters && response.InvalidParameters.length > 0) {
      console.warn('⚠️  Invalid parameters:', response.InvalidParameters);
    }

    return true;
  } catch (error) {
    console.error('❌ Failed to load parameters from AWS Systems Manager:', error);
    console.error('📝 Falling back to .env file configuration');
    
    // Don't fail the application, fall back to .env
    return false;
  }
}
