import json
import requests

BASE_URL = "http://localhost:5000"


def run_tests():
    print("=== Starting API Route Verification ===")

    # 1. Register a test user
    print("\n1. Testing POST /register...")
    reg_payload = {
        "name": "Verification User",
        "email": "verify@test.com",
        "password": "Password123!",
        "daily_calorie_goal": 2000
    }
    response = requests.post(f"{BASE_URL}/register", json=reg_payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 2. Login the user
    print("\n2. Testing POST /login...")
    login_payload = {
        "email": "verify@test.com",
        "password": "Password123!"
    }
    response = requests.post(f"{BASE_URL}/login", json=login_payload)
    print(f"Status: {response.status_code}")
    login_data = response.json()
    print(f"Response: {login_data}")
    
    if "token" not in login_data:
        print("Login failed. Cannot proceed with authenticated routes.")
        return
        
    token = login_data["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 3. GET /logs (initially empty)
    print("\n3. Testing GET /logs (Initial)...")
    response = requests.get(f"{BASE_URL}/logs", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 4. POST /manual to create a custom food item
    print("\n4. Testing POST /manual (Register custom food)...")
    food_payload = {
        "food_name": "Verify Apple",
        "calories": 95.0,
        "protein": 0.5,
        "carbs": 25.0,
        "fat": 0.3
    }
    response = requests.post(f"{BASE_URL}/manual", json=food_payload, headers=headers)
    print(f"Status: {response.status_code}")
    food_data = response.json()
    print(f"Response: {food_data}")
    
    if "food_id" not in food_data:
        print("Failed to register food item.")
        return
        
    food_id = food_data["food_id"]

    # 5. POST /log to log food intake
    print("\n5. Testing POST /log (Add food log)...")
    log_payload = {
        "food_id": food_id,
        "quantity": 2,
        "meal_type": "Breakfast",
        "protein": 1.0,
        "carbs": 50.0,
        "fat": 0.6
    }
    response = requests.post(f"{BASE_URL}/log", json=log_payload, headers=headers)
    print(f"Status: {response.status_code}")
    log_data = response.json()
    print(f"Response: {log_data}")
    
    if "log_id" not in log_data:
        print("Failed to log food.")
        return
        
    log_id = log_data["log_id"]

    # 6. GET /logs (contains logged item)
    print("\n6. Testing GET /logs (After logging)...")
    response = requests.get(f"{BASE_URL}/logs", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 7. GET /daily to get recommendations and totals
    print("\n7. Testing GET /daily...")
    response = requests.get(f"{BASE_URL}/daily", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 8. GET /predict/future (Linear Regression)
    print("\n8. Testing GET /predict/future (ML prediction)...")
    response = requests.get(f"{BASE_URL}/predict/future?day=1", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 9. PUT /user/goal
    print("\n9. Testing PUT /user/goal...")
    response = requests.put(f"{BASE_URL}/user/goal", json={"daily_calorie_goal": 2400}, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 10. DELETE /log/<log_id>
    print(f"\n10. Testing DELETE /log/{log_id}...")
    response = requests.delete(f"{BASE_URL}/log/{log_id}", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    # 11. GET /logs (verify deletion)
    print("\n11. Testing GET /logs (Verify deletion)...")
    response = requests.get(f"{BASE_URL}/logs", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    print("\n=== Verification Completed ===")


if __name__ == "__main__":
    try:
        run_tests()
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to backend server. Make sure it is running on http://localhost:5000")
