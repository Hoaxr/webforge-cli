function webforge --description 'WebForge CLI: Project builder en dev server launcher'
    set ACTION $argv[1]

    if test "$ACTION" = "create"
        _webforge_create
    else if test "$ACTION" = "start"
        _webforge_start_menu
    else
        echo "========================================================================"
        echo "                     🚀 WEBFORGE CLI [v1.0] "
        echo "========================================================================"
        echo "Gebruik:"
        echo "  webforge create   - Bouw een nieuw project"
        echo "  webforge start    - Start een bestaand project"
        echo "========================================================================"
    end
end

function _webforge_launch_server -a project_path
    echo ""
    echo "[+] Dev server starten voor "(basename $project_path)"..."

    set LOG_FILE (mktemp)
    
    if command -v alacritty >/dev/null
        nohup alacritty --working-directory $project_path -e fish -c "npm run dev | tee $LOG_FILE; or echo '[-] Server gestopt.'; read" >/dev/null 2>&1 &
    else if command -v konsole >/dev/null
        nohup konsole --workdir $project_path -e fish -c "npm run dev | tee $LOG_FILE; or echo '[-] Server gestopt.'; read" >/dev/null 2>&1 &
    end

    echo -n "[+] Wachten op server poort..."
    set -l timeout 0
    set -l gedetecteerde_url ""

    while test $timeout -lt 50
        echo -n "."
        sleep 0.1
        set timeout (math $timeout + 1)
        set gedetecteerde_url (grep -oE "http://(localhost|127\.0\.0\.1|0\.0\.0\.0):[0-9]+" $LOG_FILE | head -n 1)
        if test -n "$gedetecteerde_url"
            break
        end
    end
    echo ""

    if test -n "$gedetecteerde_url"
        set open_url (string replace -r "0\.0\.0\.0" "localhost" "$gedetecteerde_url")
        echo "[+] Gevonden! Browser openen op $open_url..."
        xdg-open "$open_url" >/dev/null 2>&1
    else
        echo "[-] Kon poort niet automatisch uitlezen uit terminal log. Probeer handmatig."
        xdg-open "http://localhost:5173" >/dev/null 2>&1
    end

    rm -f $LOG_FILE
end

function _webforge_start_menu
    set DEV_DIR "$HOME/Development"
    set OUDE_MAP (pwd)

    if not test -d $DEV_DIR
        echo "[-] Fout: De map $DEV_DIR bestaat niet."
        return 1
    end

    builtin cd $DEV_DIR
    set projects *

    if test (count $projects) -eq 0
        echo "[-] Geen projecten gevonden in $DEV_DIR."
        builtin cd $OUDE_MAP >/dev/null
        return 1
    end

    echo "========================================================================"
    echo "          🚀 KIES EEN PROJECT OM DE DEV SERVER TE STARTEN"
    echo "========================================================================"
    
    set i 1
    for project in $projects
        if test -d $project
            echo "  [$i] $project"
            set i (math $i + 1)
        end
    end
    echo "========================================================================"

    echo -n "Typ het cijfer van je project (of 'q' om te stoppen): "
    read -l keuze

    if test "$keuze" = "q"
        echo "[+] Geannuleerd."
        builtin cd $OUDE_MAP >/dev/null
        return 0
    end

    if string match -r '^[0-9]+$' -- "$keuze"; and test $keuze -ge 1; and test $keuze -lt $i
        set gekozen_project $projects[$keuze]
        set project_path "$DEV_DIR/$gekozen_project"
        _webforge_launch_server $project_path
        builtin cd $OUDE_MAP >/dev/null
        echo "[+] Succes! Je huidige terminal is weer vrij."
    else
        echo "[-] Ongeldige keuze."
        builtin cd $OUDE_MAP >/dev/null
        return 1
    end
end

function _webforge_create
    clear
    echo "========================================================================"
    echo "                     🚀 WEBFORGE CLI [v1.0] "
    echo "              De razendsnelle webproject generator"
    echo "========================================================================"
    echo ""

    read -l -p 'echo "Voer de projectnaam in: "' PROJECT_NAME
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

    echo ""
    echo "Kies de gewenste structuur voor je nieuwe project:"
    echo "------------------------------------------------------------------------"
    echo "  [1] Vite Front-end (Alleen Frontend)"
    echo "      - Supersnelle Vanilla JS setup met Vite."
    echo "      - Inclusief Prettier voor code formattering."
    echo ""
    echo "  [2] Express.js Monolith (Simpele Full-stack) ⚡"
    echo "      - Eén server die zowel de API als de frontend serveert."
    echo "      - SQLite database, Helmet beveiliging en Morgan logging."
    echo ""
    echo "  [3] Full-stack Split (Gescheiden API & Frontend) 🔥"
    echo "      - Losse Express/SQLite API server op de achtergrond."
    echo "      - Losse Vite (Vanilla JS) dev-server op de voorgrond."
    echo "      - Starten perfect gelijktijdig op via Concurrently."
    echo ""
    echo "  [4] Premium Full-stack (De Ultieme Pro Setup) 🚀"
    echo "      - Robuuste Express/SQLite API server (zoals optie 3)."
    echo "      - Vite frontend mét React en pre-configured Tailwind CSS."
    echo "      - Modern vormgegeven boilerplate startscherm."
    echo "------------------------------------------------------------------------"
    read -l -p 'echo "Kies een optie [1-4]: "' TEMPLATE_CHOICE
    set TEMPLATE_CHOICE (string trim "$TEMPLATE_CHOICE")

    function _find_free_port -a START_PORT
        set -l PORT_NUM $START_PORT
        while ss -lnt | grep -q ":$PORT_NUM "
            set PORT_NUM (math $PORT_NUM + 1)
        end
        echo $PORT_NUM
    end

    set PORT (_find_free_port 3000)

    echo ""
    echo "[+] Projectmap aanmaken in $TARGET_DIR..."
    mkdir -p $TARGET_DIR
    builtin cd $TARGET_DIR

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
        
        echo "const errorHandler = (err, req, res, next) => {
  console.error(`[Error] \${err.stack}`);
  res.status(err.statusCode || 500).json({ 
    status: 'error', 
    message: err.message || 'Interne Server Fout' 
  });
};

module.exports = errorHandler;" > middleware/errorHandler.js
        
        echo "const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, '../data/database.sqlite'));
db.exec('CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)');

module.exports = db;" > config/database.js
        
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

    if string match -q "*1*" "$TEMPLATE_CHOICE"
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

    else if string match -q "*2*" "$TEMPLATE_CHOICE"
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

    echo "[+] Code formatteren..."
    npm run format --silent
    
    echo "node_modules/
.env
.DS_Store
dist/
*.sqlite" > .gitignore
    
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
    
    if type -q code
        code . 2>/dev/null
    end
    
    functions -e _build_backend
    functions -e _find_free_port

    # --- AUTO START SERVER ---
    _webforge_launch_server $TARGET_DIR
end
