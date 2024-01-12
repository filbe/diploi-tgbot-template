import http from 'http';
import { shellExec } from './shellExec.mjs';

const Status = {
  GREEN: 'green',
  GREY: 'gray',
  YELLOW: 'yellow',
  RED: 'red',
};

const getTgbotStatus = async () => {
  try {
    const response = (await shellExec('wget -qO- https://' + process.env.API_PUBLIC_URL)).stdout;
    if (response && response.indexOf('swagger') !== -1) {
      return {
        identifier: 'api',
        name: 'API',
        description: '',
        status: Status.GREEN,
        message: '',
      };
    }

    return {
      identifier: 'api',
      name: 'API',
      status: Status.RED,
      message: 'API is not responding',
      description: '',
    };
  } catch {
    return {
      identifier: 'api',
      name: 'API',
      status: Status.RED,
      message: 'API is not responding',
      description: '',
    };
  }
};

const getStatus = async () => {
  let tgbotStatus = await getTgbotStatus();

  const status = {
    diploiStatusVersion: 1,
    items: [tgbotStatus],
  };

  return status;
};

const requestListener = async (req, res) => {
  res.writeHead(200);
  const status = await getStatus();
  res.end(JSON.stringify(status));
};

const server = http.createServer(requestListener);
server.listen(3010);

const podReadinessLoop = async (lastStatusIsOK) => {
  const status = await getStatus();
  let allOK = !status.items.find((s) => s.status !== Status.GREEN);
  if (allOK) {
    if (!lastStatusIsOK) {
      console.log(new Date(), '<STATUS> Status is OK, logging is off until next error (checks every 30s)');
    }
    await shellExec('touch /tmp/pod-ready');
  } else {
    console.log(new Date(), '<STATUS> Status not OK', status);
    setTimeout(() => {
      podReadinessLoop(allOK);
    }, 1000 + (allOK ? 1 : 0) * 30000);
  }
};
(async () => {
  podReadinessLoop(false);
})();
