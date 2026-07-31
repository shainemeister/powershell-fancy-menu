@{
    Title       = 'PsMenuKit Demo'
    Subtitle    = 'Pure PowerShell 5.1 | modular features | type to filter'
    Theme       = 'Dark'
    MultiSelect = $false
    Items       = @(
        @{
            Id      = 'hello'
            Label   = 'Say hello'
            Hotkey  = 'h'
            Handler = 'Hello'
        }
        @{
            Id      = 'time'
            Label   = 'Show local time'
            Hotkey  = 't'
            Handler = 'Time'
        }
        @{
            Id      = 'version'
            Label   = 'Show PowerShell version'
            Hotkey  = 'v'
            Handler = 'Version'
        }
        @{
            Id     = 'tools'
            Label  = 'Tools submenu'
            Hotkey = 'o'
            Children = @(
                @{
                    Id      = 'nested-a'
                    Label   = 'Nested action A'
                    Hotkey  = 'a'
                    Handler = 'NestedA'
                }
                @{
                    Id      = 'nested-b'
                    Label   = 'Nested action B'
                    Hotkey  = 'b'
                    Handler = 'NestedB'
                }
            )
        }
        @{
            Id             = 'wipe'
            Label          = 'Simulate wipe (needs confirm)'
            Hotkey         = 'w'
            Handler        = 'Wipe'
            ConfirmMessage = 'Really run simulated wipe? This is a demo only.'
        }
        @{
            Id      = 'about'
            Label   = 'About this kit'
            Hotkey  = 'a'
            Handler = 'About'
        }
        @{
            Id      = 'disabled'
            Label   = 'Coming soon (disabled)'
            Enabled = $false
        }
    )
}
