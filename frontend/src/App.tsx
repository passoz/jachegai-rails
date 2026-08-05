function App() {
  return (
    <main className="min-h-screen bg-brutal-white text-brutal-black flex items-center justify-center">
      <div className="border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white p-10 max-w-md w-full">
        <h1 className="text-4xl font-black italic mb-4">JaChegai</h1>
        <p className="text-lg mb-6 text-black/70">
          Seu delivery. Já chegou.
        </p>
        <button
          type="button"
          className="border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-brutal-black text-white font-black italic text-lg px-6 py-3 w-full hover:bg-brutal-red hover:text-brutal-black transition-all cursor-pointer"
        >
          Explorar sellers
        </button>
      </div>
    </main>
  )
}

export default App
