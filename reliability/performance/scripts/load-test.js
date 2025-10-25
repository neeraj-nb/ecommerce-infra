import http from 'k6/http';
import { sleep, check } from 'k6';

export let options = {
    vus: 50,
    duration: '30s',
    thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.01'],
    },
};

export default function () {
    let res = http.get('http://kubernetes.default.svc.cluster.local/api/health/');
    check(res, {'status is 200': (r) => 
        r.status === 200
    });
    sleep(1);
}