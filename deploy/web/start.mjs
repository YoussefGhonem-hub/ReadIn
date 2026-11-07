// The web on SmarterASP (IIS): the ASP.NET Core Module starts `node\node.exe start.mjs` out of process and passes the
// port in ASPNETCORE_PORT. This loads the Angular SSR server and listens there; IIS forwards every request to it.
// Copied next to the build by .github/workflows/uat.yml (docs/setup/deployment.md, "UAT").
import { createServer } from 'node:http';

const { reqHandler } = await import('./server/server.mjs');
const port = Number(process.env.ASPNETCORE_PORT || process.env.PORT || 4000);
createServer(reqHandler).listen(port, '127.0.0.1', () => console.log(`ReadIn web listening on 127.0.0.1:${port}`));
