-- ═══════════════════════════════════════════════════════════════
-- 하나사인몰 v3 Supabase 초기 설정
-- 실행 위치: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- v3 데이터 키-값 저장 테이블
create table if not exists v3_state (
  key text primary key,
  value text not null,
  updated_at timestamptz default now(),
  updated_by text
);

-- 빠른 조회를 위한 인덱스
create index if not exists v3_state_updated_at_idx on v3_state (updated_at desc);

-- 변경 시각 자동 갱신 트리거
create or replace function v3_state_touch() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists v3_state_touch_trigger on v3_state;
create trigger v3_state_touch_trigger
before update on v3_state
for each row execute function v3_state_touch();

-- ─── 실시간(Realtime) 활성화 ───
-- (Dashboard → Database → Replication 에서 v3_state 테이블 토글 ON 해도 됨)
alter publication supabase_realtime add table v3_state;

-- ─── Row Level Security (RLS) ───
-- 일단 익명 누구나 읽고 쓸 수 있도록 (회사 내부 사용 — URL/key가 비공개라 안전)
alter table v3_state enable row level security;

drop policy if exists "anon_read" on v3_state;
create policy "anon_read" on v3_state for select using (true);

drop policy if exists "anon_insert" on v3_state;
create policy "anon_insert" on v3_state for insert with check (true);

drop policy if exists "anon_update" on v3_state;
create policy "anon_update" on v3_state for update using (true) with check (true);

drop policy if exists "anon_delete" on v3_state;
create policy "anon_delete" on v3_state for delete using (true);

-- ─── 이미지 저장용 Storage 버킷 ───
-- (Dashboard → Storage에서 'project-images' 버킷 만들고 Public access ON 으로 설정)
-- SQL에서는 자동 생성 안 됨. Dashboard에서 수동.

-- ═══════════════════════════════════════════════════════════════
-- 설치 완료 후:
-- 1) Project Settings → API에서 'Project URL'과 'anon public' key 복사
-- 2) v3 페이지 처음 열 때 Supabase 연결 설정 prompt가 뜸 → URL/key 입력
-- 3) localStorage의 기존 데이터가 자동으로 Supabase에 마이그레이션됨
-- ═══════════════════════════════════════════════════════════════
