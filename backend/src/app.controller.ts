import { Controller, Get, Res } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';
import { Response } from 'express';

@Controller()
export class AppController {
  @Get()
  @ApiExcludeEndpoint()
  getRoot(@Res() res: Response) {
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>StreamSync Lite API</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 600px;
            width: 100%;
            padding: 40px;
            text-align: center;
        }
        h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #666;
            font-size: 1.1em;
            margin-bottom: 30px;
        }
        .status {
            display: inline-flex;
            align-items: center;
            background: #d4edda;
            color: #155724;
            padding: 10px 20px;
            border-radius: 30px;
            margin-bottom: 30px;
            font-weight: 600;
        }
        .status::before {
            content: "✓";
            display: inline-block;
            width: 20px;
            height: 20px;
            background: #28a745;
            color: white;
            border-radius: 50%;
            margin-right: 10px;
            line-height: 20px;
        }
        .links {
            display: flex;
            flex-direction: column;
            gap: 15px;
            margin-top: 30px;
        }
        a {
            display: block;
            padding: 15px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            font-weight: 600;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        a:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        .secondary {
            background: white;
            color: #667eea;
            border: 2px solid #667eea;
        }
        .secondary:hover {
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.2);
        }
        .info {
            margin-top: 30px;
            padding-top: 30px;
            border-top: 1px solid #eee;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            color: #666;
        }
        .info-label {
            font-weight: 600;
        }
        @media (max-width: 480px) {
            h1 {
                font-size: 2em;
            }
            .container {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎬 StreamSync Lite</h1>
        <p class="subtitle">Mobile Learning Video App API</p>
        
        <div class="status">API is Online</div>
        
        <div class="links">
            <a href="/api/docs" target="_blank">📖 API Documentation (Swagger)</a>
            <a href="/health" class="secondary">🏥 Health Check</a>
        </div>
        
        <div class="info">
            <div class="info-item">
                <span class="info-label">Version:</span>
                <span>1.0.0</span>
            </div>
            <div class="info-item">
                <span class="info-label">Environment:</span>
                <span>${process.env.NODE_ENV || 'production'}</span>
            </div>
            <div class="info-item">
                <span class="info-label">Uptime:</span>
                <span>${Math.floor(process.uptime())}s</span>
            </div>
        </div>
    </div>
</body>
</html>
    `;
    
    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  }
}
