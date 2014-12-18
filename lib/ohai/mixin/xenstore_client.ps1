//
// Author:: Peter Schroeter <peter.schroeter@rightscale.com>
// Author:: Stas Turlo <stanislav.turlo@rightscale.com>
// Copyright:: Copyright (c) 2010-2014 RightScale Inc
// License:: Apache License, Version 2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

param(
  [Parameter(Mandatory=$True,Position=0)][string]$command,
  [Parameter(Mandatory=$True,Position=1)][string]$value
)

function error($msg) {
  echo $msg
  exit 1
}

$sessionName = "XenStoreReader"

$session = Get-WmiObject -Namespace root\wmi -Query "select * from CitrixXenStoreSession where Id='$sessionName'"
if (!($session)) {
  $base = Get-WmiObject -Namespace root\wmi -Class CitrixXenStoreBase
  $base.AddSession($sessionName) | Out-Null
  $session = Get-WmiObject -Namespace root\wmi -Query "select * from CitrixXenStoreSession where Id='$sessionName'"
}

switch -regex ($command)
{
   "^read$"  {
     $res = $session.GetValue($value)
     if ($res) {
      return $res.value
     } else {
      error -msg "Could not find value $value"
     }
  }
  "^(ls|dir)$" {
    $res = $session.GetChildren($value)
    if ($res) {
      return $res.children.ChildNodes -replace "$value/", ""
    } else {
      error -msg "Could not find dir $value"
    }
  }
  default {
    error -msg "Unrecognized command $command. Only 'read' and 'dir' are currently supported"
  }
}
