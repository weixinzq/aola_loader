"""Single-command live probe requested by the account owner."""

from aola_offline import ReceiveTimeout

SCRIPT_NAME = "ASM240906_1 单次检测"
SCRIPT_DESCRIPTION = (
    "先订阅响应，再向扩展 42 发送一次 ASM240906_1(pi=0,n=1)；"
    "只记录提交序号和响应元数据。"
)


async def run(context):
    async with context.recv(
        lambda message: message.command == "ASM240906_1",
        max_queue=32,
    ) as response_subscription:
        receipt = await context.send(
            42,
            "ASM240906_1",
            {"pi": 0, "n": 1},
        )
        context.log(
            f"submitted ext={receipt.extension_id} cmd={receipt.command} "
            f"outer={receipt.outer_sequence} inner={receipt.inner_sequence}"
        )
        try:
            response = await response_subscription.next(timeout=15)
        except ReceiveTimeout as exc:
            raise RuntimeError(
                "已提交到 TCP 连接，但 15 秒内未收到同名 ASM240906_1 响应"
            ) from exc
        context.log(
            f"matched response type={response.message_type} "
            f"ext={response.extension_id} cmd={response.command}"
        )
