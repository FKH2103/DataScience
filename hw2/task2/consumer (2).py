import json
import logging
import os
from confluent_kafka import Consumer, Producer

# Setup Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Configuration Parameters
KAFKA_BROKER = os.getenv("KAFKA_BROKER", "localhost:9092")
CONSUMER_GROUP = "ashpaz_validation_group"

# Topics
TOPIC_IN = "ashpaz.order"
TOPIC_VALID = "ashpaz.valid"
TOPIC_ERROR = "ashpaz.error_log"

# Initialize Kafka Consumer
consumer_conf = {
    'bootstrap.servers': KAFKA_BROKER,
    'group.id': CONSUMER_GROUP,
    'auto.offset.reset': 'earliest'
}
consumer = Consumer(consumer_conf)
consumer.subscribe([TOPIC_IN])

# Initialize Kafka Producer (for routing)
producer_conf = {
    'bootstrap.servers': KAFKA_BROKER
}
producer = Producer(producer_conf)

def delivery_report(err, msg):
    if err is not None:
        logging.error(f"Message delivery failed: {err}")
    else:
        logging.debug(f"Message delivered to {msg.topic()}")

def validate_order(order):
    """
    Performs stateless validation on an incoming order payload.
    Returns a list of error strings. If the list is empty, the order is valid.
    """
    errors = []

    # Rule 1: Phone Number Format
    phone = order.get("phone_number", "")
    if not (phone.startswith("+91") or phone.startswith("080")):
        errors.append("INVALID_PHONE")

    # Rule 2: Order Mode Conflict
    request_online = order.get("request_online", False)
    request_table = order.get("request_table", False)
    if request_online and request_table:
        errors.append("ORDER_MODE_CONFLICT")

    # Rule 3: Order Price Correctness
    expected_price = 0.0
    items = order.get("items", [])
    
    for item in items:
        unit_price = item.get("unit_price", 0.0)
        quantity = item.get("quantity", 1)
        expected_price += (unit_price * quantity)

    expected_price = round(expected_price, 2)
    actual_price = order.get("order_price", 0.0)

    if expected_price != actual_price:
        errors.append("PRICE_MISMATCH")

    return errors

print("Starting the Ashpaz Validation Consumer... Press Ctrl+C to stop.")

try:
    while True:
        # Poll for new messages
        msg = consumer.poll(1.0)

        if msg is None:
            continue
        if msg.error():
            logging.error(f"Consumer error: {msg.error()}")
            continue

        # Decode and deserialize the incoming JSON payload
        try:
            raw_value = msg.value().decode('utf-8')
            order_data = json.loads(raw_value)
        except Exception as e:
            logging.error(f"Failed to decode message: {e}")
            continue

        # Pass the order through our stateless validator
        validation_errors = validate_order(order_data)

        # Routing Logic
        if not validation_errors:
            # Valid order: Route exactly as received to ashpaz.valid
            producer.produce(
                TOPIC_VALID,
                key=order_data.get("order_id"),
                value=json.dumps(order_data),
                callback=delivery_report
            )
            print(f"✅ VALID: Order {order_data.get('order_id')} routed to {TOPIC_VALID}")
            
        else:
            # Invalid order: Construct the required error payload
            error_type = validation_errors[0] if len(validation_errors) == 1 else "MULTI"
                
            error_payload = {
                "order_id": order_data.get("order_id", "UNKNOWN"),
                "error_type": error_type,
                "error_reason": validation_errors,
                "original_order": order_data
            }

            producer.produce(
                TOPIC_ERROR,
                key=order_data.get("order_id"),
                value=json.dumps(error_payload),
                callback=delivery_report
            )
            print(f"❌ INVALID ({error_type}): Order {order_data.get('order_id')} routed to {TOPIC_ERROR}")

        # Trigger any available delivery report callbacks
        producer.poll(0)

except KeyboardInterrupt:
    print("Consumer stopped by user.")
    
finally:
    consumer.close()
    producer.flush()

