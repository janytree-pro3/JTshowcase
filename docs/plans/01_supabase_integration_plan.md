# [구현 계획] 01. Supabase 연동 및 보안 암호화 적용 계획

이 문서는 클리닉스 라뉴필 VIP 쇼케이스 페이지에서 입력한 **성함, 참석 여부** 및 **VIP 한정 특별 키트 교환권 신청 내용**을 Supabase 데이터베이스에 안전하게 저장하기 위한 단계별 구현 계획서입니다.

---

## 1. 개요 및 보안 설계

사용자가 입력하는 **성함** 및 **소속**은 소중한 개인정보입니다. 웹 브라우저에서 Supabase로 데이터를 직접 전송하는 구조(클라이언트 단독 환경)에서는 Supabase API 키가 노출될 수 있으므로, 다음과 같은 보안 조치를 적용합니다.

1. **개인정보 암호화 (CryptoJS)**:
   - 데이터베이스 저장 전, 브라우저에서 **AES-256 양방향 암호화 알고리즘**을 사용하여 성함과 소속을 암호화한 뒤 저장합니다.
   - 데이터베이스가 외부로 유출되더라도, 암호화 키 없이는 원본 이름을 알 수 없어 안전합니다.
2. **Supabase RLS (Row Level Security) 설정**:
   - 데이터베이스 테이블에 쓰기(Insert) 권한만 허용하고, 일반 anon 사용자에게 읽기(Select)나 수정/삭제 권한을 차단하여 타인의 개인정보를 열람할 수 없도록 설정합니다.

---

## 2. 데이터베이스 테이블 설계 (SQL)

Supabase 대시보드의 **SQL Editor**에 실행할 SQL 스크립트입니다.
규칙에 따라 `supabase/migrations/001_initialize_schema.sql` 파일에 저장하고 관리합니다.

### 2.1 RSVP 티켓 저장 테이블 (`rsvp_tickets`)
| 컬럼명 | 데이터 타입 | 설명 |
| :--- | :--- | :--- |
| `id` | bigint (generated always as identity) | 기본키 (자동 증가) |
| `encrypted_name` | text | 암호화된 참석자 성함 |
| `attendance` | text | 참석 여부 (참석/불참) |
| `ticket_code` | text | 발급된 티켓 코드 (예: VIP-XXXX-2026) |
| `created_at` | timestamp with time zone | 신청 일시 (기본값 현재 시각) |

### 2.2 VIP 특별 키트 신청 테이블 (`gift_applications`)
| 컬럼명 | 데이터 타입 | 설명 |
| :--- | :--- | :--- |
| `id` | bigint (generated always as identity) | 기본키 (자동 증가) |
| `encrypted_name` | text | 암호화된 신청자 성함 |
| `encrypted_affiliation` | text | 암호화된 소속 (예: 제니트리 의원) |
| `voucher_code` | text | 발급된 교환권 코드 |
| `created_at` | timestamp with time zone | 신청 일시 (기본값 현재 시각) |

---

## 3. 구현 단계 (Step-by-Step)

### [1단계] Supabase 테이블 생성 및 보안 설정
- Supabase 대시보드 -> SQL Editor로 이동하여 제공된 SQL 코드를 실행해 테이블을 생성합니다.
- 테이블에 RLS(보안) 정책을 설정하여 anon 키를 통한 데이터 **추가(Insert)만 가능**하게 하고, 전체 **조회(Select)는 불가능**하게 만듭니다.

### [2단계] HTML/JS 라이브러리 추가
- `index.html`에 Supabase Client SDK와 CryptoJS(암호화 라이브러리) CDN 링크를 추가합니다.
  - CryptoJS CDN: `https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js`
  - Supabase CDN: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2`

### [3단계] 데이터 암호화 및 Supabase 연동 코드 구현
- `index.html` 내 JavaScript 코드 수정:
  1. Supabase Client 객체를 사용자의 Project URL 및 Anon Key로 초기화합니다.
  2. 비밀키(Secret Key)를 설정하여 AES-256 방식으로 성함과 소속을 암호화하는 헬퍼 함수를 정의합니다.
  3. `issueTicket()` 함수 실행 시, 성함과 참석 여부를 `rsvp_tickets` 테이블에 삽입(insert)하는 코드를 추가합니다.
  4. `issueGiftTicket()` 함수 실행 시, 성함과 소속을 `gift_applications` 테이블에 삽입(insert)하는 코드를 추가합니다.

---

## 4. 검증 계획 (Verification Plan)

### 수동 검증
1. **티켓 발급 테스트**:
   - `index.html`을 웹 브라우저로 실행합니다.
   - 성함을 입력하고 "참석"을 선택한 후 `발급하기` 버튼을 누릅니다.
   - Supabase 대시보드 -> Table Editor에서 `rsvp_tickets` 테이블에 데이터가 정상적으로 들어왔는지 확인합니다. 이때 성함이 알아볼 수 없는 문자열(암호문)로 저장되었는지 확인합니다.
2. **특별 키트 교환권 신청 테스트**:
   - 소속과 성함을 입력하고 `확인 및 교환권 발급` 버튼을 누릅니다.
   - Supabase `gift_applications` 테이블에 소속과 성함이 암호화되어 정상 저장되었는지 확인합니다.
3. **보안 검증**:
   - 브라우저 콘솔에서 익명 권한으로 타인의 데이터를 `select` 해오는 쿼리를 실행해보고, RLS에 의해 거부되는지 확인합니다.
