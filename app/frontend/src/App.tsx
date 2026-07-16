import { useCallback, useEffect, useState } from 'react'
import { getHealth, getInfo, type HealthResponse, type InfoResponse } from './api'

const features = [
  ['Immutable delivery', 'Every release is tied to one full Git commit SHA across both services.'],
  ['Private compute', 'Fargate tasks stay in private subnets and accept traffic only from the ALB.'],
  ['Reviewable changes', 'Protected approvals apply the exact Terraform plan that operators reviewed.'],
]

function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null)
  const [info, setInfo] = useState<InfoResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadStatus = useCallback(async (signal?: AbortSignal) => {
    setLoading(true); setError(null)
    try {
      const [healthResult, infoResult] = await Promise.all([getHealth(signal), getInfo(signal)])
      setHealth(healthResult); setInfo(infoResult)
    } catch (err) {
      if ((err as Error).name !== 'AbortError') setError((err as Error).message)
    } finally { if (!signal?.aborted) setLoading(false) }
  }, [])

  useEffect(() => {
    const controller = new AbortController()
    void loadStatus(controller.signal)
    return () => controller.abort()
  }, [loadStatus])

  return <>
    <header className="nav-shell">
      <nav className="nav" aria-label="Primary navigation">
        <a className="brand" href="#top" aria-label="Platform Launchpad home"><span>PL</span> Platform Launchpad</a>
        <div className="nav-links"><a href="#architecture">Architecture</a><a href="#status">Status</a><a href="#stack">Stack</a></div>
        <a className="button button-small" href="#status">View deployment</a>
      </nav>
    </header>
    <main id="main">
      <section id="top" className="hero section">
        <div className="eyebrow">AWS · ECS Fargate · Terraform</div>
        <h1>Ship infrastructure with <em>clarity</em>, not guesswork.</h1>
        <p className="hero-copy">A production-minded, multi-account reference platform with immutable containers, private workloads, and approval-gated delivery.</p>
        <div className="actions"><a className="button" href="#architecture">Explore architecture</a><a className="button secondary" href="#status">Check API health</a></div>
        <div className="metrics" aria-label="Platform highlights"><span><strong>3</strong> AWS accounts</span><span><strong>2</strong> isolated services</span><span><strong>0</strong> static cloud keys</span></div>
      </section>

      <section className="section features" aria-labelledby="features-title">
        <div><div className="eyebrow">Designed for operators</div><h2 id="features-title">A safer path from commit to cloud.</h2></div>
        <div className="card-grid">{features.map(([title, body], index) => <article className="card" key={title}><span className="card-number">0{index + 1}</span><h3>{title}</h3><p>{body}</p></article>)}</div>
      </section>

      <section id="architecture" className="section split dark-panel">
        <div><div className="eyebrow">Request architecture</div><h2>One public edge.<br/>Two private services.</h2><p>The load balancer serves the React experience by default and routes <code>/api/*</code> directly to FastAPI. Security-group references prevent direct task access.</p></div>
        <div className="flow" aria-label="Architecture flow diagram">
          <div className="flow-node accent">Internet</div><span>↓</span><div className="flow-node">Application Load Balancer</div><div className="flow-branches"><div><span>/</span><strong>React + Nginx</strong></div><div><span>/api/*</span><strong>FastAPI</strong></div></div>
        </div>
      </section>

      <section id="status" className="section status-section" aria-labelledby="status-title">
        <div><div className="eyebrow">Live deployment</div><h2 id="status-title">API health panel</h2><p>A same-origin check follows the real ALB request path. No internal cloud metadata is exposed.</p></div>
        <article className="status-card" aria-live="polite">
          {loading && <div className="state"><span className="spinner" aria-hidden="true"/>Contacting backend…</div>}
          {error && <div className="state error"><strong>Backend unavailable</strong><span>{error}</span><button className="button button-small" onClick={() => void loadStatus()}>Retry</button></div>}
          {!loading && !error && info && health && <><div className="status-heading"><span className="status-dot"/><strong>{health.status === 'healthy' ? 'All systems operational' : health.status}</strong></div><dl><div><dt>Service</dt><dd>{info.service_name}</dd></div><div><dt>Environment</dt><dd>{info.environment}</dd></div><div><dt>Version</dt><dd>{info.version}</dd></div><div><dt>Revision</dt><dd title={info.git_sha}>{info.git_sha.slice(0, 12)}</dd></div><div><dt>Server time</dt><dd>{new Date(info.server_timestamp).toLocaleString()}</dd></div><div><dt>Status</dt><dd>{info.status}</dd></div></dl></>}
        </article>
      </section>

      <section id="stack" className="section stack"><div className="eyebrow">Technology stack</div><h2>Purpose-built components.</h2><div className="pills">{['React', 'TypeScript', 'Vite', 'FastAPI', 'Nginx', 'Docker', 'ECS Fargate', 'Terraform', 'Terragrunt', 'GitHub OIDC'].map(item => <span key={item}>{item}</span>)}</div></section>
      <section className="section reliability"><div><div className="eyebrow">Reliability by default</div><h2>Observe. Scale. Recover.</h2></div><div className="reliability-grid"><p><strong>Independent scaling</strong><br/>Each service scales from one to four tasks at a 60% CPU target.</p><p><strong>Actionable alarms</strong><br/>CloudWatch detects missing tasks and load balancer server errors.</p><p><strong>Safer rollout</strong><br/>ECS circuit breakers stop unhealthy releases and restore the last deployment.</p></div></section>
    </main>
    <footer><a className="brand" href="#top"><span>PL</span> Platform Launchpad</a><p>Built for repeatable, reviewable cloud delivery.</p></footer>
  </>
}

export default App
