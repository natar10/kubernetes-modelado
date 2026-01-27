import { useState, useEffect } from 'react'

// URL del API Gateway (configurable via env)
const API_URL = window.__API_URL__ || 'http://api.eventos.local'

const services = [
  { id: 'gateway', name: 'API Gateway', endpoint: '/', color: '#6366f1' },
  { id: 'usuarios', name: 'Usuarios Service', endpoint: '/api/users', color: '#10b981' },
  { id: 'eventos', name: 'Eventos Service', endpoint: '/api/eventos', color: '#f59e0b' },
  { id: 'participacion', name: 'Participacion Service', endpoint: '/api/participacion', color: '#ef4444' },
]

function ServiceCard({ service, status, response, onTest }) {
  const isHealthy = status === 'healthy'
  const isLoading = status === 'loading'

  return (
    <div className="card">
      <div className="card-header" style={{ borderLeftColor: service.color }}>
        <h3>{service.name}</h3>
        <span className={`status ${isHealthy ? 'healthy' : isLoading ? 'loading' : 'error'}`}>
          {isLoading ? '...' : isHealthy ? 'OK' : 'Error'}
        </span>
      </div>
      <div className="card-body">
        <code className="endpoint">{API_URL}{service.endpoint}</code>
        <button onClick={() => onTest(service)} disabled={isLoading}>
          Probar Endpoint
        </button>
        {response && (
          <pre className="response">
            {JSON.stringify(response, null, 2)}
          </pre>
        )}
      </div>
    </div>
  )
}

function App() {
  const [statuses, setStatuses] = useState({})
  const [responses, setResponses] = useState({})

  // Health check inicial
  useEffect(() => {
    services.forEach(service => checkHealth(service))
  }, [])

  const checkHealth = async (service) => {
    setStatuses(prev => ({ ...prev, [service.id]: 'loading' }))
    try {
      const res = await fetch(`${API_URL}${service.endpoint}`, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      })
      const data = await res.json()
      setStatuses(prev => ({ ...prev, [service.id]: 'healthy' }))
      setResponses(prev => ({ ...prev, [service.id]: data }))
    } catch (error) {
      setStatuses(prev => ({ ...prev, [service.id]: 'error' }))
      setResponses(prev => ({ ...prev, [service.id]: { error: error.message } }))
    }
  }

  const refreshAll = () => {
    services.forEach(service => checkHealth(service))
  }

  return (
    <div className="container">
      <header>
        <h1>Eventos Platform</h1>
        <p>Cliente de prueba - Sistema Distribuido</p>
        <button className="refresh-btn" onClick={refreshAll}>
          Refrescar Todo
        </button>
      </header>

      <section className="architecture">
        <div className="arch-box">Cliente (React)</div>
        <span className="arrow">→</span>
        <div className="arch-box">Ingress</div>
        <span className="arrow">→</span>
        <div className="arch-box highlight">API Gateway</div>
        <span className="arrow">→</span>
        <div className="arch-box">Microservicios</div>
      </section>

      <main className="services-grid">
        {services.map(service => (
          <ServiceCard
            key={service.id}
            service={service}
            status={statuses[service.id]}
            response={responses[service.id]}
            onTest={checkHealth}
          />
        ))}
      </main>

      <footer>
        <p>API Gateway: <code>{API_URL}</code></p>
        <p>Practica Sistemas Distribuidos - UVA</p>
      </footer>
    </div>
  )
}

export default App
