#!/usr/bin/env python3
"""
Godot MCP Server
WebSocket server that bridges Godot MCP plugin with AI assistants.
Listens on ws://127.0.0.1:6505
"""

import asyncio
import json
import websockets
import logging
from typing import Dict, Any, Optional
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('godot-mcp')

class GodotMCPServer:
    def __init__(self, host: str = "127.0.0.1", port: int = 6505):
        self.host = host
        self.port = port
        self.clients: set = set()
        self.message_handlers: Dict[str, callable] = {
            "ping": self.handle_ping,
            "godot_ready": self.handle_godot_ready,
            "get_scene_tree": self.handle_get_scene_tree,
            "get_node_properties": self.handle_get_node_properties,
            "set_node_property": self.handle_set_node_property,
            "call_node_method": self.handle_call_node_method,
            "get_project_settings": self.handle_get_project_settings,
            "get_editor_state": self.handle_get_editor_state,
            "select_node": self.handle_select_node,
            "reload_scene": self.handle_reload_scene,
            "play_scene": self.handle_play_scene,
            "stop_scene": self.handle_stop_scene,
        }
    
    async def handle_client(self, websocket: websockets.WebSocketServerProtocol, path: str):
        """Handle a new WebSocket client connection."""
        client_id = id(websocket)
        self.clients.add(websocket)
        logger.info(f"Client {client_id} connected from {websocket.remote_address}")
        
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    response = await self.process_message(data)
                    await websocket.send(json.dumps(response))
                except json.JSONDecodeError as e:
                    logger.error(f"Invalid JSON received: {e}")
                    await websocket.send(json.dumps({
                        "status": "error",
                        "error": f"Invalid JSON: {str(e)}"
                    }))
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    await websocket.send(json.dumps({
                        "status": "error", 
                        "error": str(e)
                    }))
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Client {client_id} disconnected")
        finally:
            self.clients.discard(websocket)
    
    async def process_message(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process an incoming message and return a response."""
        message_type = data.get("type", "unknown")
        handler = self.message_handlers.get(message_type, self.handle_unknown)
        
        try:
            result = await handler(data)
            return {
                "status": "success",
                "type": message_type,
                "data": result,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Handler error for {message_type}: {e}")
            return {
                "status": "error",
                "type": message_type,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def handle_ping(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle ping messages."""
        return {"pong": True, "timestamp": datetime.now().isoformat()}
    
    async def handle_godot_ready(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle Godot editor ready notification."""
        logger.info("Godot editor is ready and connected")
        return {
            "status": "ready",
            "message": "MCP server acknowledged Godot ready",
            "features": [
                "scene_tree_inspection",
                "node_property_access",
                "method_calling",
                "editor_control",
                "project_settings_access"
            ]
        }
    
    async def handle_get_editor_state(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Get current editor state."""
        return {
            "editor_state": {
                "current_scene": "unknown",
                "selected_nodes": [],
                "is_playing": False,
                "is_paused": False
            },
            "note": "Editor state will be fetched from Godot"
        }
    
    async def handle_select_node(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Select a node in the editor."""
        node_path = data.get("node_path", "")
        return {
            "node_path": node_path,
            "selected": True,
            "note": f"Node {node_path} will be selected in Godot editor"
        }
    
    async def handle_reload_scene(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Reload the current scene."""
        return {
            "reloaded": True,
            "note": "Scene will be reloaded in Godot"
        }
    
    async def handle_play_scene(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Play the current scene."""
        return {
            "playing": True,
            "note": "Scene will start playing in Godot"
        }
    
    async def handle_stop_scene(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Stop the running scene."""
        return {
            "stopped": True,
            "note": "Scene will stop in Godot"
        }
    
    async def handle_get_scene_tree(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Get the current scene tree from Godot."""
        return {
            "message": "Scene tree request received",
            "note": "Godot plugin needs to implement scene tree serialization"
        }
    
    async def handle_get_node_properties(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Get properties of a specific node."""
        node_path = data.get("node_path", "")
        return {
            "node_path": node_path,
            "properties": {},
            "note": "Properties will be fetched from Godot"
        }
    
    async def handle_set_node_property(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Set a property on a specific node."""
        node_path = data.get("node_path", "")
        property_name = data.get("property", "")
        value = data.get("value")
        return {
            "node_path": node_path,
            "property": property_name,
            "value": value,
            "note": "Property will be set in Godot"
        }
    
    async def handle_call_node_method(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Call a method on a specific node."""
        node_path = data.get("node_path", "")
        method = data.get("method", "")
        args = data.get("args", [])
        return {
            "node_path": node_path,
            "method": method,
            "args": args,
            "note": "Method will be called in Godot"
        }
    
    async def handle_get_project_settings(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Get Godot project settings."""
        return {
            "settings": {},
            "note": "Project settings will be fetched from Godot"
        }
    
    async def handle_unknown(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle unknown message types."""
        return {
            "error": f"Unknown message type: {data.get('type')}",
            "supported_types": list(self.message_handlers.keys())
        }
    
    async def start(self):
        """Start the WebSocket server."""
        logger.info(f"Starting Godot MCP Server on ws://{self.host}:{self.port}")
        
        async with websockets.serve(
            self.handle_client, 
            self.host, 
            self.port,
            ping_interval=20,
            ping_timeout=10
        ):
            logger.info(f"Server running on ws://{self.host}:{self.port}")
            logger.info("Waiting for Godot MCP plugin connections...")
            
            # Keep running until interrupted
            await asyncio.Future()


def main():
    """Main entry point."""
    server = GodotMCPServer(host="127.0.0.1", port=6505)
    
    try:
        asyncio.run(server.start())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        raise


if __name__ == "__main__":
    main()
