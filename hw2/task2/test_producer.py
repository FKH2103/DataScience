from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Invalid order: phone invalid + mode conflict (price is correct)
test_order = {
    "order_id": "12345",
    "user_id": "user1",
    "restaurant_id": "rest1",
    "restaurant_name": "Kebab House",
    "restaurant_city": "Tehran",
    "cuisines": ["Kebab"],
    "phone_number": "09123456789",        # Invalid (should start with +91 or 080)
    "request_online": True,
    "request_table": True,                 # Conflict
    "order_time": "2025-01-01T12:00:00Z",
    "items": [
        {"item_id": "i1", "unit_price": 100, "quantity": 2}
    ],
    "order_price": 200                    # Correct price
}

producer.send('ashpaz.order', test_order)
producer.flush()
print("Test message sent.")