-- 1. RSVP 티켓 정보 저장 테이블 생성
CREATE TABLE IF NOT EXISTS public.rsvp_tickets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_name TEXT NOT NULL,         -- 암호화된 참석자 성함
    attendance TEXT NOT NULL,             -- 참석 여부 (참석 / 불참)
    ticket_code TEXT NOT NULL,            -- 발급된 티켓 코드
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. VIP 특별 키트 신청 정보 저장 테이블 생성
CREATE TABLE IF NOT EXISTS public.gift_applications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_name TEXT NOT NULL,         -- 암호화된 신청자 성함
    encrypted_affiliation TEXT NOT NULL,  -- 암호화된 소속
    voucher_code TEXT NOT NULL,           -- 발급된 교환권 코드
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Row Level Security (RLS) 보안 활성화
-- RLS를 활성화하면 정책(Policy)이 없는 한 기본적으로 모든 사용자의 접근(읽기/쓰기 등)이 차단됩니다.
ALTER TABLE public.rsvp_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_applications ENABLE ROW LEVEL SECURITY;

-- 4. 익명 사용자(anon/public)의 데이터 삽입(Insert)만 허용하는 보안 정책 생성
-- 이 설정을 통해 홈페이지 방문자는 데이터를 추가(쓰기)할 수만 있고, 다른 사람의 데이터를 조회(Select)하거나 수정/삭제할 수 없습니다.

-- rsvp_tickets 테이블에 대한 쓰기 권한 부여
CREATE POLICY "Allow anonymous inserts to rsvp_tickets" 
ON public.rsvp_tickets 
FOR INSERT 
TO anon 
WITH CHECK (true);

-- gift_applications 테이블에 대한 쓰기 권한 부여
CREATE POLICY "Allow anonymous inserts to gift_applications" 
ON public.gift_applications 
FOR INSERT 
TO anon 
WITH CHECK (true);
