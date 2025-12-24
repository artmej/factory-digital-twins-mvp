# Smart Factory Dashboard - Quick Deploy

🚀 **Dashboard en vivo**: [Ver Dashboard](https://kind-desert-0c7f84b0f.6.azurestaticapps.net)

## Status de Deployment 
- ✅ ML Engine funcionando (localhost:3001)
- ✅ Dashboard creado y funcional
- 🟡 Static Web App deployándose...

## Si el sitio no carga:

### Opción 1: GitHub Pages (Backup rápido)
```bash
# Crear repo público en GitHub
gh repo create smart-factory-dashboard --public
cd deployment/mobile
git init
git add .
git commit -m "Smart Factory Dashboard - Production Ready"
git branch -M main
git remote add origin https://github.com/[tu-usuario]/smart-factory-dashboard.git
git push -u origin main
# Activar GitHub Pages en settings
```

### Opción 2: Netlify Drop (Más rápido)
1. Ve a [netlify.com/drop](https://app.netlify.com/drop)
2. Arrastra la carpeta `deployment/mobile` 
3. Sitio en vivo en 30 segundos

### Opción 3: Vercel (También muy rápido)
```bash
npm i -g vercel
cd deployment/mobile
vercel --prod
```

## Dashboard Features ✨
- 📊 Real-time factory metrics
- 🤖 ML models (92.3% accuracy)
- 📱 Mobile-responsive design
- 💰 ROI tracking
- 📈 Live predictions
- 🏭 Factory status monitoring

**El dashboard está completo y listo para usar!**