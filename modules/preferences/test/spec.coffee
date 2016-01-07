describe 'hx-preferences', ->
  describe 'api', ->
    it 'supportedLocales: setter/getter', ->
      list = ["uz", "vi", "cy"]
      expect(hx.preferences.supportedLocales(list)).toEqual(hx.preferences)
      expect(hx.preferences.supportedLocales()).toEqual(list)

    it 'locale: should not be possible to explicitly clear the locale', ->
      # sanity check
      expect(hx.preferences.locale()).toBeDefined()

      hx.preferences.locale undefined
      expect(hx.preferences.locale()).toBeDefined()


    it 'locale: setter/getter', ->
      expect(hx.preferences.locale('vi')).toEqual(hx.preferences)
      expect(hx.preferences.locale()).toEqual('vi')

    it 'locale: setter/getter with alternative casing', ->
      expect(hx.preferences.locale('en-GB')).toEqual(hx.preferences)
      expect(hx.preferences.locale()).toEqual('en-GB')

    it 'locale: setter/getter should correct the casing', ->
      expect(hx.preferences.locale('en-gb')).toEqual(hx.preferences)
      expect(hx.preferences.locale()).toEqual('en-GB')

    it 'locale: dont emit when setting to the same value', ->
      hx.preferences.locale('en-GB')
      called = false
      hx.preferences.on 'localechange', -> called = true
      hx.preferences.locale('en-GB')
      expect(called).toEqual(false)

    it 'locale: dont emit when setting to the same value', ->
      hx.preferences.locale('en-GB')
      called = false
      hx.preferences.on 'localechange', -> called = true
      hx.preferences.locale('en-us')
      expect(called).toEqual(true)

    it 'locale: setter/getter for non supported value', ->
      spyOn(hx, 'consoleWarning')
      expect(hx.preferences.locale('vi')).toEqual(hx.preferences)
      expect(hx.preferences.locale('lemon')).toEqual(hx.preferences)
      expect(hx.preferences.locale()).toEqual('vi')
      expect(hx.consoleWarning).toHaveBeenCalled()
    describe 'timezone', ->
      it 'setter/getter', ->
        expect(hx.preferences.timezone('UTC+01:00')).toEqual(hx.preferences)
        expect(hx.preferences.timezone()).toEqual('UTC+01:00')

      it 'dont emit when setting to the same value', ->
        hx.preferences.timezone('UTC+00:00')
        called = false
        hx.preferences.on 'timezonechange', -> called = true
        hx.preferences.timezone('UTC+00:00')
        expect(called).toEqual(false)

      it 'emit when setting to new value', ->
        hx.preferences.timezone('UTC+00:00')
        called = false
        hx.preferences.on 'timezonechange', -> called = true
        hx.preferences.timezone('UTC+01:00')
        expect(called).toEqual(true)
