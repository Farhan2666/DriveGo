import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://nfeyfscqiqaoitjyudji.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mZXlmc2NxaXFhb2l0anl1ZGppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MjMzODgsImV4cCI6MjA5NTM5OTM4OH0.iWJKR15JOrGlhExBbNBu-SxwSkb9vJ1OrXcvpPtESwk';

export const supabase = createClient(supabaseUrl, supabaseKey);
