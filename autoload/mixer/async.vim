vim9script

# Run a job with a pointer to a list to store the job output in memory. 
export def Append(cmd: string, append_output_to: list<any>): void
  job_start(["sh", "-c", cmd], {
    out_cb: function("GatherOutput", [append_output_to]),
    mode: "nl"
  })
enddef

def GatherOutput(collector: list<string>, channel: channel, output: string)
  add(collector, output)
enddef
