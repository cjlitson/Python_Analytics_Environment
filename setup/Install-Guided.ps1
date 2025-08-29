<#!
.SYNOPSIS
  Guided installer for the Python Analytics Environment.
.DESCRIPTION
  Presents a simple GUI to choose Admin or User mode and calls the
  appropriate installer script.
#>

[CmdletBinding()]
param()

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Python Analytics Environment Setup"
        SizeToContent="WidthAndHeight"
        WindowStartupLocation="CenterScreen">
  <StackPanel Margin="20" Width="400">
    <TextBlock Text="Select installation type:" Margin="0,0,0,10" FontWeight="Bold" />
    <RadioButton Name="AdminOption" Content="Admin install" IsChecked="True" />
    <StackPanel Margin="20,5,0,10">
      <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
        <TextBlock Width="150" VerticalAlignment="Center">Miniconda root:</TextBlock>
        <TextBox Name="RootBox" Width="200" Text="C:\ProgramData\Miniconda3" />
      </StackPanel>
      <CheckBox Name="AdsCheck" Content="Include Azure Data Studio" />
    </StackPanel>
    <RadioButton Name="UserOption" Content="User install" />
    <StackPanel Margin="20,5,0,10">
      <StackPanel Orientation="Horizontal">
        <TextBlock Width="150" VerticalAlignment="Center">Environment name:</TextBlock>
        <TextBox Name="EnvBox" Width="200" Text="Analytics" />
      </StackPanel>
    </StackPanel>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="OkButton" Width="75" Margin="0,10,5,0">Install</Button>
      <Button Name="CancelButton" Width="75" Margin="0,10,0,0">Cancel</Button>
    </StackPanel>
  </StackPanel>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$AdminOption = $window.FindName("AdminOption")
$UserOption  = $window.FindName("UserOption")
$RootBox     = $window.FindName("RootBox")
$AdsCheck    = $window.FindName("AdsCheck")
$EnvBox      = $window.FindName("EnvBox")
$OkButton    = $window.FindName("OkButton")
$CancelButton= $window.FindName("CancelButton")

$CancelButton.Add_Click({ $window.Close() })
$OkButton.Add_Click({
    if ($AdminOption.IsChecked) {
        $params = @{ MinicondaRoot = $RootBox.Text }
        if ($AdsCheck.IsChecked) { $params.IncludeAzureDataStudio = $true }
        & "$PSScriptRoot/Install-Admin.ps1" @params
    }
    elseif ($UserOption.IsChecked) {
        & "$PSScriptRoot/Install-User.ps1" -EnvName $EnvBox.Text
    }
    $window.Close()
})

$window.ShowDialog() | Out-Null

