@{
    Title       = 'PsMenuKit MultiSelect Demo'
    Subtitle    = 'Space toggles markers; Enter runs all selected (or focused if none)'
    Theme       = 'Dark'
    MultiSelect = $true
    Items       = @(
        @{
            Id      = 'a'
            Label   = 'Pick A'
            Hotkey  = 'a'
            Handler = 'PickA'
        }
        @{
            Id      = 'b'
            Label   = 'Pick B'
            Hotkey  = 'b'
            Handler = 'PickB'
        }
        @{
            Id      = 'c'
            Label   = 'Pick C'
            Hotkey  = 'c'
            Handler = 'PickC'
        }
        @{
            Id             = 'wipe'
            Label          = 'Simulated wipe (confirm each if selected)'
            Hotkey         = 'w'
            Handler        = 'Wipe'
            ConfirmMessage = 'Really include simulated wipe in this batch?'
        }
    )
}
