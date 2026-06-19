function mksite --description 'De ultieme webproject builder gesynchroniseerd met het start-script'
    clear
    echo "========================================================================"
    echo "          🚀 WELKOM BIJ DE ULTIEME WEBPROJECT BUILDER [v5.4]"
    echo "========================================================================"
    echo ""

    # 1. PROJECTNAAM OPVRAGEN
    read -l -p 'echo "Voer de projectnaam in (bijv. mijn-nieuwe-app): "' PROJECT_NAME
    set PROJECT_NAME (string trim "$PROJECT_NAME")
    if test -z "$PROJECT_NAME"
        echo "[-] Fout: Projectnaam is verplicht."
        return 1
    end

    set TARGET_DIR "$HOME/Development/$PROJECT_NAME"

    if test -d $TARGET_DIR
        echo "[-] Fout: Map $TARGET_DIR bestaat al."
        return 1
    end

    # 2. INTERACTIEF MENU
    echo ""
    echo "Kies de gewenste structuur voor je nieuwe project:"
    echo "------------------------------------------------------------------------"
    echo "  [1] Express.js Monolith (Production-Ready) ⚡"
    echo "  [2] Vite Front-end (Vanilla JS)"
    echo "  [3] Full-stack Split (Express API + Vite Vanilla JS) 🔥"
    echo "  [4] Premium Full-stack (Express API + Vite React + Tailwind CSS) 🔥"
    echo "------------------------------------------------------------------------"
    read -l -p 'echo "Kies een optie [1-4]: "' TEMPLATE_CHOICE
    set TEMPLATE_CHOICE (string trim "$TEMPLATE_CHOICE")

    # HELPER FUNCTIES (Deze worden aan het eind weer opgeruimd)
    function _find_free_port -a START_PORT
        set -l PORT_NUM $START_PORT
        while ss -lnt | grep -q ":$PORT_NUM "
            set PORT_NUM (math $PORT_NUM + 1)
        end
        echo $PORT_NUM
    end

    # Vrije poort zoeken vanaf 3000
    set PORT (_find_free_port 3000)

    echo ""
    echo "[+] Projectmap aanmaken in $TARGET_DIR..."
    mkdir -p $TARGET_DIR
    builtin cd $TARGET_DIR

    # 3. GEDEELDE CONFIGURATIES (Prettier)
    echo '{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}' > .prettierrc

    echo "node_modules/
dist/
.env
*.sqlite" > .prettierignore

    # INTERNE FUNCTIE VOOR PRO BACKEND
    function _build_backend -a PORT PROJECT_NAME
        mkdir -p config routes middleware data
        echo '{
  "name": "'$PROJECT_NAME'-server",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js"
  },
  "dependencies": {
    "better-sqlite3": "^11.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0"
  }
}' > package.json
        
        # Error handler
        echo "const errorHandler = (err, req, res, next) => {
  console.error(`[Error] \${err.stack}`);
  res.status(err.statusCode || 500).json({ 
    status: 'error', 
    message: err.message || 'Interne Server Fout' 
  });
};

module.exports = errorHandler;" > middleware/errorHandler.js
        
        # Database
        echo "const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, '../data/database.sqlite'));
db.exec('CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)');

module.exports = db;" > config/database.js
        
        # Routes
        echo "const express = require('express');
const router = express.Router();
const db = require('../config/database');

router.get('/status', (req, res, next) => {
  try {
    db.prepare('INSERT INTO logs (message) VALUES (?)').run('API opgevraagd');
    const c = db.prepare('SELECT COUNT(*) as count FROM logs').get();
    res.json({
      status: 'success',
      message: '🚀 API online & beveiligd!',
      database: `SQLite (Logs: \${c.count})`,
      tech: ['Express', 'Helmet', 'Morgan', 'SQLite3']
    });
  } catch(e) {
    next(e);
  }
});

module.exports = router;" > routes/api.js
        
        # Index
        echo "require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const apiRoutes = require('./routes/api');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || $PORT;

app.use(helmet());
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());

app.use('/api', apiRoutes);
app.use(errorHandler);

app.listen(PORT, () => console.log(`[Backend] Server op poort \${PORT}`));" > index.js
        
        echo "PORT=$PORT
NODE_ENV=development" > .env
        npm install --silent
    end

    # 4. TEMPLATE LOGICA
    if string match -q "*1*" "$TEMPLATE_CHOICE"
        echo "[+] Productie-ready Express.js Monolith opbouwen..."
        mkdir -p public server
        builtin cd server
        _build_backend $PORT $PROJECT_NAME
        builtin cd ..
        sed -i "s|app.use('/api', apiRoutes);|app.use(express.static(path.join(__dirname, '../public')));\nconst path = require('path');\napp.use('/api', apiRoutes);|" server/index.js
        
        echo "<!DOCTYPE html>
<html>
<head>
  <title>Monolith</title>
</head>
<body>
  <h1 style=\"text-align:center;margin-top:20%;\">🚀 $PROJECT_NAME Monolith</h1>
  <p id=\"m\" style=\"text-align:center;\"></p>
  <script>
    fetch(\"/api/status\")
      .then(r => r.json())
      .then(d => document.getElementById(\"m\").innerText = d.message);
  </script>
</body>
</html>" > public/index.html
        
        echo '{
  "name": "'$PROJECT_NAME'",
  "version": "1.0.0",
  "scripts": {
    "dev": "node --watch server/index.js",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "prettier": "^3.2.5"
  }
}' > package.json
        npm install --silent

    else if string match -q "*2*" "$TEMPLATE_CHOICE"
        echo "[+] Vite Front-end template opbouwen..."
        echo '{
  "name": "'$PROJECT_NAME'",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --port '$PORT' --host --clearScreen false",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "prettier": "^3.2.5",
    "vite": "^5.2.11"
  }
}' > package.json
        
        echo "<!DOCTYPE html>
<html>
<body>
  <div id=\"app\" style=\"text-align:center;margin-top:20%;\">
    <h1>⚡ $PROJECT_NAME (Vite)</h1>
  </div>
  <script type=\"module\" src=\"/main.js\"></script>
</body>
</html>" > index.html
        
        echo "import './style.css';" > main.js
        echo "body { background: #111827; color: white; font-family: sans-serif; }" > style.css
        npm install --silent

    else if string match -q "*3*" "$TEMPLATE_CHOICE"
        echo "[+] Full-stack Split (Vanilla + Pro Backend) opbouwen..."
        mkdir -p server; builtin cd server; _build_backend $PORT $PROJECT_NAME; builtin cd ..
        mkdir -p client; builtin cd client
        
        set VITE_PORT (_find_free_port (math $PORT + 1))
        
        echo '{
  "name": "'$PROJECT_NAME'-client",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --port '$VITE_PORT' --host --clearScreen false"
  },
  "devDependencies": {
    "vite": "^5.2.11"
  }
}' > package.json

        echo "<!DOCTYPE html>
<html>
<body>
  <div id=\"app\" style=\"text-align:center;margin-top:20%;\">
    <h1>⚡ Vanilla Split</h1>
    <p id=\"s\">Laden...</p>
  </div>
  <script type=\"module\" src=\"/main.js\"></script>
</body>
</html>" > index.html
        
        echo "fetch('http://localhost:$PORT/api/status')
  .then(r => r.json())
  .then(d => document.getElementById('s').innerText = d.message);" > main.js
        
        npm install --silent
        builtin cd ..
        echo '{
  "name": "'$PROJECT_NAME'",
  "private": true,
  "scripts": {
    "dev": "concurrently --kill-others \"npm run dev --prefix server\" \"npm run dev --prefix client\"",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "concurrently": "^8.2.2",
    "prettier": "^3.2.5"
  }
}' > package.json
        npm install --silent

    else
        echo "[+] Premium Full-stack (React + Tailwind + Pro Backend) opbouwen..."
        mkdir -p server; builtin cd server; _build_backend $PORT $PROJECT_NAME; builtin cd ..
        mkdir -p client; builtin cd client
        
        set VITE_PORT (_find_free_port (math $PORT + 1))
        
        echo '{
  "name": "'$PROJECT_NAME'-client",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --port '$VITE_PORT' --host --clearScreen false"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.3",
    "vite": "^5.2.11"
  }
}' > package.json

        echo "import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()]
});" > vite.config.js

        echo "export default {
  content: [\"./index.html\", \"./src/**/*.{js,ts,jsx,tsx}\"],
  theme: { extend: {} },
  plugins: []
};" > tailwind.config.js

        echo "export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};" > postcss.config.js

        echo "<!DOCTYPE html>
<html>
<head>
  <title>React</title>
</head>
<body class=\"bg-slate-900 text-slate-100 min-h-screen\">
  <div id=\"root\"></div>
  <script type=\"module\" src=\"/src/main.jsx\"></script>
</body>
</html>" > index.html
        
        mkdir -p src
        echo "@tailwind base;
@tailwind components;
@tailwind utilities;" > src/index.css

        echo "import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(<App />);" > src/main.jsx

        echo "import { useState, useEffect } from 'react';

function App() {
  const [apiData, setApiData] = useState({ message: 'Laden...', database: '' });

  useEffect(() => {
    fetch('http://localhost:$PORT/api/status')
      .then(res => res.json())
      .then(data => setApiData(data));
  }, []);

  return (
    <div className=\"flex flex-col items-center justify-center min-h-screen bg-slate-950\">
      <div className=\"bg-slate-900 border border-slate-800 p-8 rounded-2xl shadow-2xl text-center max-w-sm\">
        <h1 className=\"text-3xl font-black text-cyan-400 mb-2\">🚀 $PROJECT_NAME</h1>
        <p className=\"text-emerald-400 font-mono text-sm mb-2\">{apiData.message}</p>
        <p className=\"text-xs text-slate-500\">{apiData.database}</p>
      </div>
    </div>
  );
}

export default App;" > src/App.jsx

        npm install --silent
        builtin cd ..
        
        echo '{
  "name": "'$PROJECT_NAME'",
  "private": true,
  "scripts": {
    "dev": "concurrently --kill-others \"npm run dev --prefix server\" \"npm run dev --prefix client\"",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "concurrently": "^8.2.2",
    "prettier": "^3.2.5"
  }
}' > package.json
        npm install --silent
    end

    # 5. POETSEN & COMMITTEN
    echo "[+] Code formatteren..."
    npm run format --silent
    echo "node_modules/
.env
.DS_Store
dist/
*.sqlite" > .gitignore
    
    # Git init fixes (quiet i.p.v. silent)
    git init -b main --quiet
    git add .
    git commit -m "Initial commit" --quiet

    if command -v gh >/dev/null
        echo "[+] Private repo op GitHub aanmaken..."
        gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push >/dev/null 2>&1
    end

    echo ""
    echo "========================================================================"
    echo "🎉 PROJECT SUCCESVOL LIVE GEZET ALS NATIVE FISH APP!"
    echo "========================================================================"
    
    # Check of code-alias of VS Code daadwerkelijk bestaat voor het openen
    if type -q code
        code . 2>/dev/null
    end
    
    # Tijdelijke functies opruimen
    functions -e _build_backend
    functions -e _find_free_port
end