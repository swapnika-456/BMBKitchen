import os
import sys
import re
import json
import io
import datetime
import email.utils
import requests

BASE_URL = "https://bmbproducts.com"
ORG_ID = "6ac78e4f0a063d3e07a1bed5"
OUTLET_ID = "6adc341988e080704d1fb5af" # THROWAWAY_ORDER_TEST_OUTLET

EMAIL = os.environ.get("BMB_TEST_EMAIL")
PASSWORD = os.environ.get("BMB_TEST_PASSWORD")

if not EMAIL or not PASSWORD:
    print("ERROR: Both BMB_TEST_EMAIL and BMB_TEST_PASSWORD environment variables must be set.", file=sys.stderr)
    print("Example usage:", file=sys.stderr)
    print("  BMB_TEST_EMAIL=\"user@bmb.com\" BMB_TEST_PASSWORD=\"secret\" python tool/live_checks/run_audit.py", file=sys.stderr)
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "live_audit_raw_output.txt")
log_fp = open(OUTPUT_FILE, "w", encoding="utf-8")

def redact_secrets(text: str) -> str:
    if not text:
        return text
    # JWT tokens
    text = re.sub(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}', '<REDACTED_JWT_TOKEN>', text)
    # Password hashes ($2a$, $2b$, $2y$)
    text = re.sub(r'\$2[aby]\$\d+\$[./A-Za-z0-9]{53}', '<REDACTED_BCRYPT_HASH>', text)
    # JSON password fields
    text = re.sub(r'"password"\s*:\s*"[^"]*"', '"password": "<REDACTED_PASSWORD>"', text)
    text = re.sub(r'"token"\s*:\s*"[^"]*"', '"token": "<REDACTED_TOKEN>"', text)
    # Authorization header
    text = re.sub(r'Bearer\s+[A-Za-z0-9._-]+', 'Bearer <REDACTED_TOKEN>', text)
    return text

def log(line: str = ""):
    safe = redact_secrets(line)
    print(safe)
    log_fp.write(safe + "\n")
    log_fp.flush()

def decode_object_id_timestamp(oid_str: str):
    if len(oid_str) == 24:
        try:
            ts = int(oid_str[:8], 16)
            return datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc)
        except Exception:
            return None
    return None

def extract_and_verify_object_ids(data, header_date_str: str):
    header_dt = None
    if header_date_str and header_date_str != "N/A":
        try:
            header_dt = email.utils.parsedate_to_datetime(header_date_str)
        except Exception:
            header_dt = None

    found_oids = set()
    def search_obj(val, parent_key=""):
        if isinstance(val, dict):
            for k, v in val.items():
                if k in ("_id", "id", "createdBy", "updatedBy", "orderId", "menuItemId", "categoryId", "outletId", "vendorId") and isinstance(v, str) and len(v) == 24:
                    found_oids.add((k, v))
                elif isinstance(v, (dict, list)):
                    search_obj(v, k)
        elif isinstance(val, list):
            for item in val:
                search_obj(item, parent_key)

    search_obj(data)

    if found_oids:
        log("-" * 40)
        log("OBJECT_ID TIMESTAMPS VS HTTP DATE HEADER:")
        for key, oid in sorted(found_oids):
            oid_dt = decode_object_id_timestamp(oid)
            if oid_dt and header_dt:
                diff_sec = abs((oid_dt - header_dt).total_seconds())
                flag_str = ""
                if diff_sec > 300: # 5 minutes
                    flag_str = f" [FLAG: Diff {diff_sec:.1f}s > 5m]"
                log(f"  Field: {key} | _id: {oid} | Decoded UTC: {oid_dt.strftime('%Y-%m-%d %H:%M:%S UTC')} | Response Date: {header_dt.strftime('%Y-%m-%d %H:%M:%S UTC')} | Diff: {diff_sec:.1f}s{flag_str}")
            elif oid_dt:
                log(f"  Field: {key} | _id: {oid} | Decoded UTC: {oid_dt.strftime('%Y-%m-%d %H:%M:%S UTC')} | Response Date: {header_date_str}")
        log("-" * 40)

session = requests.Session()

def api_call(method: str, url: str, json_body=None, data=None, files=None, headers=None, description=""):
    log("=" * 80)
    if description:
        log(f"SCENARIO: {description}")
    log(f"METHOD: {method.upper()}")
    log(f"FULL URL: {url}")
    if json_body is not None:
        log(f"REQUEST BODY (JSON): {json.dumps(json_body)}")
    elif data is not None:
        log(f"REQUEST BODY (FORM DATA): {data}")
    elif files is not None:
        log(f"REQUEST FILES: {list(files.keys()) if isinstance(files, dict) else [f[0] for f in files]}")
    else:
        log("REQUEST BODY: None")

    req_headers = {}
    if headers:
        req_headers.update(headers)

    m = method.upper()
    if m == "GET":
        resp = session.get(url, headers=req_headers)
    elif m == "POST":
        if files or data:
            h = dict(session.headers)
            h.pop("Content-Type", None)
            if headers:
                h.update(headers)
            resp = session.post(url, data=data, files=files, headers=h)
        else:
            resp = session.post(url, json=json_body, headers=req_headers)
    elif m == "PUT":
        if files or data:
            h = dict(session.headers)
            h.pop("Content-Type", None)
            if headers:
                h.update(headers)
            resp = session.put(url, data=data, files=files, headers=h)
        else:
            resp = session.put(url, json=json_body, headers=req_headers)
    elif m == "PATCH":
        resp = session.patch(url, json=json_body, headers=req_headers)
    elif m == "DELETE":
        resp = session.delete(url, headers=req_headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    date_header = resp.headers.get("Date", "N/A")
    log(f"RESPONSE HTTP DATE HEADER: {date_header}")
    log(f"HTTP STATUS: {resp.status_code}")
    log(f"RESPONSE BODY: {resp.text}")

    try:
        parsed_json = resp.json()
        extract_and_verify_object_ids(parsed_json, date_header)
    except Exception:
        pass

    log("=" * 80)
    return resp

def run_dashboard_audit():
    log("\n" + "#" * 80)
    log("PART B: MODULE 25 DASHBOARD READ-ONLY TESTS (#159 to #165)")
    log(f"TARGET OUTLET: {OUTLET_ID}")
    log("#" * 80)

    base = f"{BASE_URL}/api/dashboard/v1/{ORG_ID}/{OUTLET_ID}"

    # -------------------------------------------------------------------------
    # 1. SCOPE = TODAY
    # -------------------------------------------------------------------------
    log("\n--- MODULE 25: scope=today ---")
    api_call("GET", f"{base}/summary?scope=today", None, description="#159 GET /summary (scope=today)")
    api_call("GET", f"{base}/sales-kpis?scope=today", None, description="#160 GET /sales-kpis (scope=today)")
    api_call("GET", f"{base}/sales-by-trend?scope=today", None, description="#161 GET /sales-by-trend (scope=today)")
    api_call("GET", f"{base}/kitchen-ticket-status?scope=today", None, description="#162 GET /kitchen-ticket-status (scope=today)")
    api_call("GET", f"{base}/top-selling-items?scope=today", None, description="#163 GET /top-selling-items (scope=today)")
    api_call("GET", f"{base}/payment-summary?scope=today", None, description="#164 GET /payment-summary (scope=today)")
    api_call("GET", f"{base}/quick-stats?scope=today", None, description="#165 GET /quick-stats (scope=today)")

    # -------------------------------------------------------------------------
    # 2. CUSTOM SCOPE: 2026-10-24 to 2026-10-24
    # -------------------------------------------------------------------------
    log("\n--- MODULE 25: scope=custom & from=2026-10-24 & to=2026-10-24 ---")
    api_call("GET", f"{base}/summary?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#159 GET /summary (2026-10-24)")
    api_call("GET", f"{base}/sales-kpis?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#160 GET /sales-kpis (2026-10-24)")
    api_call("GET", f"{base}/sales-by-trend?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#161 GET /sales-by-trend (2026-10-24)")
    api_call("GET", f"{base}/kitchen-ticket-status?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#162 GET /kitchen-ticket-status (2026-10-24)")
    api_call("GET", f"{base}/top-selling-items?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#163 GET /top-selling-items (2026-10-24)")
    api_call("GET", f"{base}/payment-summary?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#164 GET /payment-summary (2026-10-24)")
    api_call("GET", f"{base}/quick-stats?scope=custom&from=2026-10-24&to=2026-10-24", None, description="#165 GET /quick-stats (2026-10-24)")

    # -------------------------------------------------------------------------
    # 3. SCOPE = MONTH
    # -------------------------------------------------------------------------
    log("\n--- MODULE 25: scope=month ---")
    api_call("GET", f"{base}/summary?scope=month", None, description="#159 GET /summary (scope=month)")
    api_call("GET", f"{base}/sales-kpis?scope=month", None, description="#160 GET /sales-kpis (scope=month)")
    api_call("GET", f"{base}/sales-by-trend?scope=month", None, description="#161 GET /sales-by-trend (scope=month)")
    api_call("GET", f"{base}/kitchen-ticket-status?scope=month", None, description="#162 GET /kitchen-ticket-status (scope=month)")
    api_call("GET", f"{base}/top-selling-items?scope=month", None, description="#163 GET /top-selling-items (scope=month)")
    api_call("GET", f"{base}/payment-summary?scope=month", None, description="#164 GET /payment-summary (scope=month)")
    api_call("GET", f"{base}/quick-stats?scope=month", None, description="#165 GET /quick-stats (scope=month)")

    # -------------------------------------------------------------------------
    # 4. LIMIT & COMPARISON TESTS
    # -------------------------------------------------------------------------
    log("\n--- MODULE 25: LIMIT PARAMETER TEST on #163 & #159 ---")
    api_call("GET", f"{base}/top-selling-items?scope=month&limit=1", None, description="#163 GET /top-selling-items (limit=1)")
    api_call("GET", f"{base}/summary?scope=month&limit=1", None, description="#159 GET /summary (limit=1)")

    # -------------------------------------------------------------------------
    # 5. CUSTOM SCOPE to=2026-10-25 (Checking inclusive vs exclusive boundary)
    # -------------------------------------------------------------------------
    log("\n--- MODULE 25: to=2026-10-25 Boundary Test ---")
    api_call("GET", f"{base}/summary?scope=custom&from=2026-10-24&to=2026-10-25", None, description="#159 GET /summary (2026-10-24 to 2026-10-25)")

def main():
    machine_utc = datetime.datetime.now(datetime.timezone.utc)
    log("=" * 80)
    log(f"MACHINE UTC CLOCK AT START: {machine_utc.strftime('%Y-%m-%d %H:%M:%S UTC')} (epoch: {int(machine_utc.timestamp())})")
    log(f"MACHINE LOCAL TIME: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log(f"OUTPUT LOG FILE: {OUTPUT_FILE}")
    log("=" * 80)

    # AUTHENTICATION
    log("\n>>> AUTHENTICATION >>>")
    res_login = api_call("POST", f"{BASE_URL}/api/auth/v1/login", {"email": EMAIL, "password": PASSWORD}, description="Login for auth token")
    if res_login.status_code != 200:
        log(f"FATAL: Login failed with status {res_login.status_code}")
        sys.exit(1)

    login_data = res_login.json()
    token = login_data.get("token") or login_data.get("data", {}).get("token")
    session.headers.update({"Authorization": f"Bearer {token}", "Content-Type": "application/json"})

    run_dashboard_audit()

    log("\n" + "=" * 80)
    log("MODULE 25 DASHBOARD AUDIT COMPLETED.")
    log(f"Raw output written to: {OUTPUT_FILE}")
    log("=" * 80)

if __name__ == "__main__":
    main()
