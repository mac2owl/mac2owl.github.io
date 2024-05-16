# Redis

## Cache helper

```py
from typing import TYPE_CHECKING, Any, Optional

import redis

from app.config.config import config

if TYPE_CHECKING:
    from datetime import datetime


class RedisCache:
    def __init__(self, decode_responses=True) -> None:
        host = config.redis_db.host
        port = config.redis_db.port
        self.redis_client = redis.StrictRedis(host=host, port=port, decode_responses=decode_responses)

    def set(self, key: str, value: Any) -> Optional[bool]:
        self.redis_client.set(key, value)

    def get(self, key: str) -> Optional[bytes]:
        return self.redis_client.get(key)

    def set_key_expire_at(self, key: str, expire_at: "datetime") -> None:
        if self.redis_client.exists(key):
            self.redis_client.expireat(key, expire_at)

    def get_keys_by_pattern(self, keys_pattern: str) -> list:
        return [cache_key for cache_key in self.redis_client.scan_iter(keys_pattern)]

    def delete_keys_by_pattern(self, keys_pattern: str) -> list:
        for cache_key in self.redis_client.scan_iter(keys_pattern):
            self.redis_client.delete(cache_key)

    def flushall(self) -> None:
        self.redis_client.flushall()

    def exists(self, key) -> int:
        return self.redis_client.exists(key)

    def store_and_set_expire(self, cache_key: str, data: str, expire_at: "datetime") -> None:
        self.set(cache_key, data)
        self.set_key_expire_at(cache_key, expire_at)
```

## Events streaming with Redis Stream

[Redis documentation on Stream](https://redis.io/docs/latest/develop/data-types/streams/)  
[Use of consumer groups](https://www.infoworld.com/article/3321938/how-to-use-consumer-groups-in-redis-streams.html)  
[Redis-py](https://redis-py.readthedocs.io/en/stable/examples/redis-stream-example.html)

### Publisher

```py
import json

from concurrent import futures
from datetime import datetime
from typing import Any

import redis

from logger import Logger



class EventsPublisher:
    def __init__(self, event_stream_name: str) -> None:
        self.logger = Logger().get_logger()
        self.event_stream_name = event_stream_name
				self._publisher = None

		@properity
		def publisher(self):
			if self._publisher is None:
				self._publisher = redis.Redis(
					host=config.event_publisher.host,
					port=config.event_publisher.port,
					db=config.event_publisher.database,
				)
			return self._publisher

    def batch_add(self, payloads: list, id_key="obj_id") -> tuple[list[str], list[str]]:
        successful_entries_ids = []
        failed_obj_ids = []

        with futures.ThreadPoolExecutor() as executor:
            tasks = [executor.submit(self.add, payload, False, id_key) for payload in payloads]
            for task in futures.as_completed(tasks):
                try:
                    entry_id, obj_id = task.result()
                    if entry_id is not None:
                        successful_entries_ids.append(entry_id)
                    else:
                        failed_obj_ids.append(obj_id)
                except Exception:
                    self.logger.exception("Error pushing data to stream")

        return successful_entries_ids, failed_obj_ids

    def add(self, payload: Any, raise_error=True, id_key="id") -> tuple[str, str]:
        obj_id = payload.get(id_key)
        obj_type = payload.get("obj_type")
        action = payload.get("action") # create / update etc

        try:
            json_payload = json.dumps(payload)
            self.logger.info("Pushing %s data (%s) with ID %s to stream", obj_type, action, obj_id)
            entry_id = self.publisher.xadd(self.event_stream_name, {"payload": json_payload})
            entry_id = entry_id.decode("utf-8")
            self.logger.info(
                "%s data (%s) with ID %s pushed - entry_id %s", obj_type, action, obj_id, entry_id
            )
            return entry_id, obj_id
        except (
            TypeError,
            redis.exceptions.ConnectionError,
            redis.exceptions.TimeoutError,
            redis.exceptions.RedisError,
        ) as e:
            msg = f"Failed to push {obj_type} data ({action}) with ID {obj_id} to stream: {str(e)}"
            self.logger.info(msg)
            if raise_error:
                raise e
            return None, obj_id

    def delete(self, msg_id: str) -> dict[str, int]:
        status = self.publisher.xdel(self.event_stream_name, msg_id)
        return {msg_id: status}

    def get_list(self, msg_count=10):
        event_msgs = self.publisher.xread({self.event_stream_name: "0-0"}, count=msg_count)
        data = {}
        if not event_msgs:
            return data

        for message in event_msgs[0][1]:
            message_id = message[0].decode("utf-8")

            try:
                message_body = message[1]
                payload = message_body.get(b"payload")
                payload = payload.decode("utf-8") if payload else {}
            except Exception:
                payload = {}
            data[message_id] = payload

        return data
```

### Consumer (One consumer - no additional consumer groups)

```py
import asyncio
import json

from typing import Any

from redis import asyncio as aioredis

from path.to.config import config



class EventsConsumer:
    def __init__(self, app) -> None:
        app.app_context().push()
        self.logger = logger

    async def handle_event(self, payload: dict) -> None:
			# process the event message body
			await process_event_message(payload)


    async def main(self) -> Any:
        consumer_config = config.event_consumer
        consumer_host = consumer_config.stream_host
        consumer_port = consumer_config.stream_port
        consumer_database = consumer_config.stream_database
        consumer_stream = consumer_config.stream

        redis = await aioredis.from_url(
            f"redis://{consumer_host}:{consumer_port}",
            db=consumer_database,
            encoding="utf8",
            decode_responses=True,
        )
        message_id = "0-0"

        while True:
            events = await redis.xread({consumer_stream: message_id})
            if not events:
                await asyncio.sleep(1)

            for stream, message in events:
                message_id = message[0][0]
                payload = message[0][1]["payload"]
                payload = json.loads(payload)

                await self.handle_event(payload)
                await redis.xdel(stream, message_id)
```

To start consumer as thread:

```py
def start_event_consumer():
	asyncio.run(EventsConsumer(app).main())

worker = threading.Thread(target=start_event_consumer, args=[])
worker.start()
```

## Consumer groups

Create consumer group(s) [XGROUP CREATE](https://redis.io/docs/latest/commands/xgroup-create/):

```py
redis_client.xgroup_create(name=stream_name, groupname=gname, id=0)
```

Read with consumer group(s) [XREADGROUP](https://redis.io/docs/latest/commands/xreadgroup/):

```py
redis_client.xreadgroup(groupname=group_1, consumername='consumer_a', streams={stream_key:'>'})
```

Acknowledge messages [XACK](https://redis.io/docs/latest/commands/xack/):

```py
redis_client.xack(stream_name, groupname, message_id)
```
