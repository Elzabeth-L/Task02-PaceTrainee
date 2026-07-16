# Monitoring

Frontend and backend logs are separate JSON/stdout CloudWatch log groups retained for seven days. FastAPI logs request ID, method, path, response code, and duration without sensitive headers. Alarms detect two consecutive minutes with zero healthy targets for either target group and repeated ALB-generated 5xx responses. Optional SNS action ARNs connect alarms to notifications.

Autoscaling uses standard ECS average CPU metrics, so Container Insights and custom metrics remain off by default. Dashboards, ALB access logs, latency/4xx alarms, log metric filters, tracing, and synthetic canaries are production additions. Alert responders should check ALB target health, ECS deployment events, stopped-task reasons, and log streams in that order.
