import http from 'k6/http';
import { check } from 'k6';
import { SharedArray } from 'k6/data';
import exec from 'k6/execution';

// 1. โหลดข้อมูลจาก users.json เข้า Memory (ทำครั้งเดียว)
const users = new SharedArray('users_data', function () {
    return JSON.parse(open('./users.json'));
});

// 2. กำหนดโครงสร้างการรัน Load Test
export const options = {
    scenarios: {
        unique_users_login: {
            executor: 'shared-iterations',
            vus: 20,                  // จำนวน VUs ที่จะช่วยกันดึง User ไปยิง
            iterations: users.length, // บังคับให้ยิงรวมกันเท่ากับจำนวน User ในไฟล์พอดีเป๊ะ
            maxDuration: '30m',       // กำหนด Timeout สำรองกันสคริปต์ค้าง
        },
    },
};

export default function () {
    // 3. ดึง Index รวมของทั้งระบบ (0, 1, 2, ..., users.length - 1)
    const currentIndex = exec.scenario.iterationInTest;

    //เช็กป้องกันกรณี Index เกินขนาด Array (เพื่อความปลอดภัย)
    if (currentIndex >= users.length) {
        exec.test.abort('ใช้อ่านข้อมูล User หมดแล้ว - สั่งหยุดการทำงาน');
        return;
    }

    // ดึง User ประจำ Iteration นี้
    const currentUser = users[currentIndex];

    // 4. เตรียม Payload ยิง API Login (Keycloak)
    const url = 'http://localhost:8080/realms/test/protocol/openid-connect/token';
    const payload = {
        grant_type: 'password',
        client_id: 'client-0',
        client_secret: 'client-0-secret',
        username: currentUser.username,
        password: currentUser.password,
        scope: 'openid',
    };

    const params = {
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
    };

    // 5. ส่ง HTTP POST
    const res = http.post(url, payload, params);

    // 6. ตรวจสอบผลลัพธ์
    check(res, {
        'status is 200': (r) => r.status === 200,
        'has access_token': (r) => r.json('access_token') !== undefined,
    });
}







