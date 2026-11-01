#!/usr/bin/env python3
"""
Pre-Release Smoke Test Script: Read-only GETs on every list endpoint.
Runs all queries without any mutations or writes.
Credentials are read strictly from environment variables:
  BMB_TEST_EMAIL
  BMB_TEST_PASSWORD
"""

import os
import sys
import json
import datetime
import requests

BASE_URL = os.environ.get("BMB_BASE_URL", "https://bmbproducts.com")
EMAIL = os.environ.get("BMB_TEST_EMAIL")
PASSWORD = os.environ.get("BMB_TEST_PASSWORD")

if not EMAIL or not PASSWORD:
    print("ERROR: Both BMB_TEST_EMAIL and BMB_TEST_PASSWORD environment variables must be set.", file=sys.stderr)
    print("Example usage:", file=sys.stderr)
    print("  BMB_TEST_EMAIL=\"user@bmb.com\" BMB_TEST_PASSWORD=\"secret\" python tool/live_checks/smoke.py", file=sys.stderr)
    sys.exit(1)

session = requests.Session()

def extract_count(data) -> int:
    if isinstance(data, list):
        return len(data)
    if isinstance(data, dict):
        # Look for common wrapper fields
        for key in ['items', 'orders', 'users', 'tables', 'tickets', 'transfers', 'requests', 'categories', 'recipes', 'vendors', 'history', 'notifications', 'printers', 'rates']:
            if key in data and isinstance(data[key], list):
                return len(data[key])
        if 'data' in data:
            return extract_count(data['data'])
        if 'total' in data and isinstance(data['total'], int):
            return data['total']
        if 'count' in data and isinstance(data['count'], int):
            return data['count']
        return 1
    return 0

def run_smoke():
    print("=" * 84)
    print(f"BMB KITCHEN PRE-RELEASE SMOKE AUDIT [READ-ONLY]")
    print(f"Target: {BASE_URL}")
    print("=" * 84)

    # 1. Authenticate
    login_url = f"{BASE_URL}/api/auth/v1/login"
    login_resp = session.post(login_url, json={"email": EMAIL, "password": PASSWORD})
    if login_resp.status_code != 200:
        print(f"FAILED to login: HTTP {login_resp.status_code} - {login_resp.text}", file=sys.stderr)
        sys.exit(1)

    login_data = login_resp.json()
    token = login_data.get("token")
    user_info = login_data.get("data", {})
    session.headers.update({"Authorization": f"Bearer {token}"})

    org_data = user_info.get("organizationId")
    org_id = org_data.get("_id") if isinstance(org_data, dict) else org_data
    if not org_id:
        print("ERROR: Could not resolve organization ID from user session.", file=sys.stderr)
        sys.exit(1)

    # 2. Resolve Outlets to obtain active outletId
    outlets_resp = session.get(f"{BASE_URL}/api/outlet/v1/{org_id}")
    outlets_data = outlets_resp.json().get("data", [])
    if isinstance(outlets_data, dict) and "outlets" in outlets_data:
        outlets_data = outlets_data["outlets"]
    outlet_id = outlets_data[0]["_id"] if outlets_data and isinstance(outlets_data, list) and len(outlets_data) > 0 else "default"

    today_str = datetime.date.today().isoformat()

    print(f"Authenticated as: {user_info.get('userName')} ({user_info.get('role')})")
    print(f"Organization ID : {org_id}")
    print(f"Active Outlet ID: {outlet_id}")
    print("-" * 84)
    print(f"{'Endpoint Description':<34} | {'Status':<6} | {'Count':<6} | {'HTTP Date Header'}")
    print("-" * 84)

    # Exact endpoints matching all 25 modules in the codebase
    endpoints = [
        ("Auth Check / Current User", f"/api/auth/v1/isauthenticated", {}),
        ("Users List", f"/api/auth/", {"limit": 10}),
        ("Organizations List", f"/api/organization/v1/", {}),
        ("Current Organization", f"/api/organization/v1/{org_id}", {}),
        ("Outlets List", f"/api/outlet/v1/{org_id}", {}),
        ("Roles & Permissions", f"/api/role/v1/{org_id}", {}),
        ("Menu Categories", f"/api/menu-category/v1/{org_id}", {"outletId": outlet_id}),
        ("Menu Items", f"/api/menu-item/v1/{org_id}", {"outletId": outlet_id}),
        ("Tables List", f"/api/table/v1/{org_id}", {"outletId": outlet_id}),
        ("Dine-In Orders List", f"/api/orders/v1/{org_id}/dine-in", {"outletId": outlet_id}),
        ("Takeaway Orders List", f"/api/orders/v1/{org_id}/takeaway", {"outletId": outlet_id}),
        ("Delivery Orders List", f"/api/orders/v1/{org_id}/delivery", {"outletId": outlet_id}),
        ("Online Orders List", f"/api/orders/v1/{org_id}/orders", {"type": "online", "outletId": outlet_id}),
        ("Kitchen Status / Queue", f"/api/dashboard/v1/{org_id}/{outlet_id}/kitchen-status", {}),
        ("Inventory Stock Items", f"/api/inventory/v1/{org_id}", {"outletId": outlet_id}),
        ("Inventory Dropdown", f"/api/inventory/v1/{org_id}/dropdown", {}),
        ("Purchase Orders", f"/api/purchase/v1/{org_id}", {}),
        ("Vendors List", f"/api/vendor/v1/{org_id}", {}),
        ("Recipes List", f"/api/recipe-cost/v1/{org_id}", {}),
        ("Wastage Adjustments", f"/api/wastage-adjustments/v1/{org_id}", {}),
        ("Payments List", f"/api/payment/v1/{org_id}", {"outletId": outlet_id}),
        ("Day Closing Summary", f"/api/day-closing/v1/{org_id}/{outlet_id}/summary", {"date": today_str}),
        ("Central Kitchen Active", f"/api/central-kitchen/v1/{org_id}", {}),
        ("Subscriptions List", f"/api/subscription/v1/{org_id}", {}),
        ("Notifications List", f"/api/notification/v1/{org_id}", {}),
        ("Support Tickets List", f"/api/support-ticket/v1/{org_id}", {}),
        ("Tax Settings", f"/api/tax-settings/v1/{org_id}", {}),
        ("Printer Settings", f"/api/printer/v1/{org_id}", {}),
        ("Integrations List", f"/api/integration/v1/{org_id}", {}),
        ("Reports Sales", f"/api/report/v1/{org_id}/sales", {}),
        ("Dashboard Summary", f"/api/dashboard/v1/{org_id}/{outlet_id}/summary", {}),
    ]

    total = len(endpoints)
    passed = 0

    for name, path, params in endpoints:
        url = f"{BASE_URL}{path}"
        try:
            resp = session.get(url, params=params)
            date_hdr = resp.headers.get("Date", "N/A")
            status = resp.status_code
            count_str = "-"

            if status in (200, 201):
                try:
                    payload = resp.json()
                    item_count = extract_count(payload.get("data", payload))
                    count_str = str(item_count)
                    passed += 1
                except Exception:
                    count_str = "JSON?"
            else:
                count_str = "ERR"

            print(f"{name:<34} | {status:<6} | {count_str:<6} | {date_hdr}")
        except Exception as e:
            print(f"{name:<34} | {'EXC':<6} | {'-':<6} | {str(e)[:30]}")

    print("-" * 84)
    print(f"Results: {passed}/{total} endpoints returned HTTP 200 OK.")
    print("=" * 84)

if __name__ == "__main__":
    run_smoke()
