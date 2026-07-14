import mermaid from 'mermaid'

mermaid.initialize({
  startOnLoad: false,
  securityLevel: 'strict',
  theme: window.darkMode ? 'dark' : 'default',
})

const renderDiagrams = () => {
  const nodes = document.querySelectorAll('pre.mermaid:not([data-processed="true"])')
  if (nodes.length) mermaid.run({ nodes })
}

document.addEventListener('turbo:load', renderDiagrams)
if (document.readyState === 'complete') renderDiagrams()
