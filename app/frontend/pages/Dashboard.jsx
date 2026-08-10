import Layout from '../components/Layout'

export default function Dashboard({ day }) {
  return (
    <Layout>
      <h1 className="text-xl font-semibold">Schedule for {day}</h1>
      <p className="mt-2 text-sm text-slate-600">Calendar coming next.</p>
    </Layout>
  )
}
