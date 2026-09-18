from kafka import KafkaConsumer, KafkaProducer
import json
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def validate_phone(phone):
    """
    Validation of phone number format.
    Must be INVALID_PHONE for both missing and invalid format
    """
    if not phone:
        return False, "INVALID_PHONE"  
    if phone.startswith(("+91", "080")):
        return True, None
    return False, "INVALID_PHONE"

def validate_mode(online, table):
    if online and table:
        return False, "ORDER_MODE_CONFLICT"
    return True, None

def validate_price(order):
    total = sum(item.get("unit_price", 0) * item.get("quantity", 0) for item in order.get("items", []))
    provided = order.get("order_price", 0)
    if abs(total - provided) > 0.01:
        return False, "PRICE_MISMATCH"
    return True, None

# ایجاد Kafka Consumer
consumer = KafkaConsumer(
    'ashpaz.order',
    bootstrap_servers='localhost:9092',
    group_id='ashpaz-validation-group',
    auto_offset_reset='earliest',
    enable_auto_commit=False,
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

# ایجاد Kafka Producer
producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

logger.info("Consumer started. Waiting for messages...")

for msg in consumer:
    order = msg.value
    order_id = order.get("order_id", "unknown")
    errors = []

    # Phone Validation
    ok, err = validate_phone(order.get("phone_number"))
    if not ok:
        errors.append(err)

    # Mode Conflict Validation
    ok, err = validate_mode(order.get("request_online", False), order.get("request_table", False))
    if not ok:
        errors.append(err)

    # Price Validation
    ok, err = validate_price(order)
    if not ok:
        errors.append(err)

    if not errors:
        logger.info(f"Valid order: {order_id}")
        producer.send('ashpaz.valid', order)
    else:
        logger.warning(f"Invalid order {order_id}: errors = {errors}")
        error_payload = {
            "order_id": order_id,
            "error_type": "MULTI" if len(errors) > 1 else errors[0],
            "error_reason": errors,
            "original_order": order
        }
        producer.send('ashpaz.error_log', error_payload)

    producer.flush()
    consumer.commit()