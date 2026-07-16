import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import App from '../src/App'

const health = { status: 'healthy', service: 'platform-api' }
const info = { service_name:'platform-api', version:'1.0.0', git_sha:'abcdef1234567890', environment:'test', server_timestamp:'2026-01-01T00:00:00Z', python_version:'3.13.1', status:'operational' }
function ok(body: object) { return Promise.resolve(new Response(JSON.stringify(body), { status: 200, headers:{'Content-Type':'application/json'} })) }

afterEach(() => vi.restoreAllMocks())
describe('Platform Launchpad', () => {
  it('renders the landing page', () => { vi.stubGlobal('fetch', vi.fn(() => new Promise(() => {}))); render(<App/>); expect(screen.getByRole('heading', {name:/ship infrastructure/i})).toBeInTheDocument() })
  it('shows loading state', () => { vi.stubGlobal('fetch', vi.fn(() => new Promise(() => {}))); render(<App/>); expect(screen.getByText(/contacting backend/i)).toBeInTheDocument() })
  it('renders successful API data', async () => { vi.stubGlobal('fetch', vi.fn((path:string) => path.endsWith('health') ? ok(health) : ok(info))); render(<App/>); expect(await screen.findByText('All systems operational')).toBeInTheDocument(); expect(screen.getByText('platform-api')).toBeInTheDocument() })
  it('renders an API failure', async () => { vi.stubGlobal('fetch', vi.fn(() => Promise.resolve(new Response('',{status:503})))); render(<App/>); expect(await screen.findByText('Backend unavailable')).toBeInTheDocument() })
  it('retries after failure', async () => { const fetchMock=vi.fn().mockResolvedValueOnce(new Response('',{status:500})).mockResolvedValueOnce(new Response('',{status:500})).mockImplementation((path:string) => path.endsWith('health') ? ok(health) : ok(info)); vi.stubGlobal('fetch', fetchMock); render(<App/>); await userEvent.click(await screen.findByRole('button',{name:'Retry'})); await waitFor(() => expect(screen.getByText('All systems operational')).toBeInTheDocument()); expect(fetchMock).toHaveBeenCalledTimes(4) })
})
