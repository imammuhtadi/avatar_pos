# Deployment Guide - Avatar POS to Coolify

This guide explains how to deploy the Avatar POS Flutter web application to Coolify with automatic rebuilds on every push.

## Prerequisites

- Coolify instance running and accessible
- GitHub repository with the project
- Docker installed on Coolify server

## Setup Steps

### 1. Prepare Your Coolify Instance

1. Log in to your Coolify dashboard
2. Create a new project or select an existing one
3. Add a new resource → **Docker Compose** or **Dockerfile**

### 2. Configure Coolify Application

#### Option A: Using GitHub Integration (Recommended)

1. In Coolify, create a new application
2. Select **GitHub** as the source
3. Connect your GitHub account if not already connected
4. Select the `avatar_pos` repository
5. Choose the branch to deploy (e.g., `main` or `dev`)
6. Set the following:
   - **Build Pack**: `Dockerfile`
   - **Dockerfile Location**: `./Dockerfile`
   - **Port**: `80`
   - **Auto Deploy**: Enable this to rebuild on every push

#### Option B: Using Webhook (Alternative)

1. In Coolify, go to your application settings
2. Find the **Webhook URL** (looks like: `https://your-coolify.com/api/v1/deploy/webhook/...`)
3. Copy the webhook URL and token

### 3. Configure GitHub Secrets (For Webhook Method)

If using the webhook method:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:
   - `COOLIFY_WEBHOOK_URL`: Your Coolify webhook URL
   - `COOLIFY_TOKEN`: Your Coolify API token (if required)

### 4. Environment Variables

**IMPORTANT**: Flutter web apps bundle environment variables at **build time**, not runtime. Set these as **Build Arguments** in Coolify:

#### In Coolify Dashboard:

1. Go to your application → **Environment Variables**
2. Add the following variables:

```bash
# Supabase Configuration (Build-time)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

These variables will be passed to Docker as build arguments and baked into the `.env` file during the build process.

#### How It Works:

1. **Build Time**: Coolify passes environment variables as Docker build arguments
2. **Dockerfile**: Creates `.env` file with these values
3. **Flutter Build**: Bundles `.env` into the web app
4. **Runtime**: App reads from the bundled `.env` file

**Note**: If you change environment variables, you must **rebuild** the application for changes to take effect.

### 5. Deploy

#### Automatic Deployment (GitHub Integration)

- Simply push to your configured branch
- Coolify will automatically detect the push and rebuild

#### Manual Deployment (Webhook)

- Push to GitHub
- GitHub Actions will trigger the Coolify webhook
- Coolify will pull the latest code and rebuild

## Project Structure

```
avatar_pos/
├── Dockerfile              # Multi-stage build for Flutter web
├── docker-compose.yml      # Docker Compose configuration
├── nginx.conf             # Nginx configuration for serving Flutter web
├── .dockerignore          # Files to exclude from Docker build
├── .github/
│   └── workflows/
│       └── deploy.yml     # GitHub Actions workflow
└── lib/                   # Flutter application code
```

## Build Process

The Dockerfile uses a multi-stage build:

1. **Stage 1**: Build Flutter web app

   - Uses official Flutter Docker image
   - Runs `flutter pub get`
   - Builds web app with `flutter build web --release`

2. **Stage 2**: Serve with Nginx
   - Uses lightweight Nginx Alpine image
   - Copies built web app to Nginx html directory
   - Serves on port 80

## Nginx Configuration

The `nginx.conf` includes:

- Gzip compression for better performance
- Security headers
- Cache control for static assets
- SPA routing support (serves index.html for all routes)
- Health check endpoint at `/health`

## Monitoring

### Health Check

Access `https://your-domain.com/health` to verify the application is running.

### Logs

View logs in Coolify dashboard:

1. Go to your application
2. Click on **Logs** tab
3. View build and runtime logs

## Troubleshooting

### Build Fails

- Check Coolify build logs
- Verify Dockerfile syntax
- Ensure all dependencies are in `pubspec.yaml`

### Application Not Loading

- Check nginx logs in Coolify
- Verify port 80 is exposed
- Check if health endpoint responds: `curl https://your-domain.com/health`

### Environment Variables Not Working

- Verify variables are set in Coolify
- For Flutter web, environment variables need to be injected at build time
- Consider using a config file or build-time arguments

## Updating the Application

1. Make changes to your code
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin main  # or dev
   ```
3. Coolify will automatically:
   - Detect the push
   - Pull latest code
   - Rebuild Docker image
   - Deploy new version
   - Zero-downtime deployment

## Custom Domain

1. In Coolify, go to your application settings
2. Add your custom domain
3. Coolify will automatically provision SSL certificate via Let's Encrypt
4. Update your DNS records to point to Coolify server

## Performance Tips

1. **Enable Gzip**: Already configured in nginx.conf
2. **Cache Static Assets**: Configured with 1-year expiry
3. **Use CanvasKit Renderer**: Already set in Dockerfile
4. **Optimize Images**: Use WebP format where possible
5. **Code Splitting**: Flutter web handles this automatically

## Security

- SSL/TLS is handled by Coolify
- Security headers are set in nginx.conf
- Keep dependencies updated
- Use environment variables for sensitive data
- Never commit API keys or secrets

## Rollback

If you need to rollback to a previous version:

1. In Coolify, go to **Deployments** tab
2. Find the previous successful deployment
3. Click **Redeploy**

Or via Git:

```bash
git revert HEAD
git push origin main
```

## Support

For issues:

- Check Coolify documentation: https://coolify.io/docs
- Review build logs in Coolify dashboard
- Check GitHub Actions logs for webhook issues
