import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    vus: 50, // virtual users
    duration: '1m',
    thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.01'],
    },
};

// Change this to your Kubernetes service name and namespace
const SERVICE_NAME = 'product-service';
const NAMESPACE = 'product-service';
const PORT = 8000;
const BASE_URL = `http://${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:${PORT}`;

export default function () {
    let res = http.get(`${BASE_URL}/api/products/`);
    check(res, {
        'status is 200': (r) => r.status === 200,
        'body is not empty': (r) => r.body.length > 0,
    });
    sleep(1);
}
