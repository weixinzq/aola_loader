"""Trusted-script example that only waits for one server message."""

SCRIPT_NAME = "示例：等待一条消息"
SCRIPT_DESCRIPTION = "登录后等待并记录下一条服务器消息；本示例不会主动发送。"


async def run(context):
    async with context.recv() as subscription:
        message = await subscription.next(timeout=30)
        context.log(
            f"received type={message.message_type} "
            f"ext={message.extension_id} cmd={message.command}"
        )

