const app = require('./app');
const { port } = require('./config/env');

app.listen(port, () => console.log(`CheckLizz API escuchando en el puerto ${port}`));
