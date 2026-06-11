import asyncio
import json
import websockets

async def verify():
    uri = "ws://127.0.0.1:8000/ws"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            payload = {
                "text": "I am so anxious and scared that I might fail",
                "context": "Friendship",
                "mode": "chat",
                "persona": "Friendship Coach"
            }
            await websocket.send(json.dumps(payload))
            print("Payload sent. Waiting for response...")
            response = await websocket.recv()
            data = json.loads(response)
            print("\nResponse Received:")
            print(json.dumps(data, indent=2))
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(verify())
