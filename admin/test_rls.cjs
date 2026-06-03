const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = 'https://nfeyfscqiqaoitjyudji.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mZXlmc2NxaXFhb2l0anl1ZGppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MjMzODgsImV4cCI6MjA5NTM5OTM4OH0.iWJKR15JOrGlhExBbNBu-SxwSkb9vJ1OrXcvpPtESwk';
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const { data, error } = await supabase.from('users').select('*').eq('phone', '08120000000').single();
  console.log("Data:", data);
  console.log("Error:", error);
}
run();
