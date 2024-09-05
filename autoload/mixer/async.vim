vim9script

# Run a job with a pointer to a list to store the job output in memory. 
def Append(cmd: string, append_output_to: list<string>)
  call job_start(["sh", "-c", cmd], {
    out_cb: function("s:gather_output", [append_output_to]),
    mode: "nl"
  })
enddef

def GatherOutput(collector: list<string>, channel: channel, result: list<string>)
  add(result)
enddef
