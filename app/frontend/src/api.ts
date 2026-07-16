export interface HealthResponse { status: string; service: string }
export interface InfoResponse {
  service_name: string
  version: string
  git_sha: string
  environment: string
  server_timestamp: string
  python_version: string
  status: string
}

async function getJson<T>(path: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(path, { headers: { Accept: 'application/json' }, signal })
  if (!response.ok) throw new Error(`Service returned HTTP ${response.status}`)
  return response.json() as Promise<T>
}

export const getHealth = (signal?: AbortSignal) => getJson<HealthResponse>('/api/health', signal)
export const getInfo = (signal?: AbortSignal) => getJson<InfoResponse>('/api/info', signal)
