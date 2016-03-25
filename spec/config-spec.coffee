describe 'Linter Config', ->
  linter = null
  {getLinter} = require('./common')
  Path = require('path')
  FS = require('fs')
  TempDir = require('os').tmpdir()

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  describe 'ignoreMatchedFiles', ->
    it 'ignores the file if it matches pattern', ->
      filePath = Path.join(TempDir, 'linter_spec_ignored_match.min.js')
      FS.writeFileSync(filePath, 'Hello Dolly')

      atom.config.set('linter.ignoreGlob', '{\,/}**{\,/}*.min.{js,css}')
      linterProvider = getLinter()
      spyOn(linterProvider, 'lint')

      linter.addLinter(linterProvider)

      waitsForPromise ->
        atom.workspace.open(filePath).then ->
          atom.workspace.getActiveTextEditor().terminatePendingState()
          linter.commands.lint()
          expect(linterProvider.lint).not.toHaveBeenCalled()
          atom.config.set('linter.ignoreGlob', '{\,/}**{\,/}*.min.css')
          linter.commands.lint()
          expect(linterProvider.lint).toHaveBeenCalled()
          FS.unlinkSync(filePath)

  describe 'excludeVcsIgnoredPaths', ->
    ignoredFilePath = Path.join(__dirname, 'fixtures', 'ignored.txt')

    it 'determines if a file is going to be excluded or not', ->
      FS.writeFileSync(ignoredFilePath, 'Hello World')

      linterProvider = getLinter()
      spyOn(linterProvider, 'lint')

      linter.addLinter(linterProvider)
      atom.config.set('core.excludeVcsIgnoredPaths', false)
      atom.project.addPath(Path.normalize(Path.join(__dirname, '..')))

      waitsForPromise ->
        atom.workspace.open(ignoredFilePath).then ->
          atom.workspace.getActiveTextEditor().terminatePendingState()
          linter.commands.lint()
          expect(linterProvider.lint).toHaveBeenCalled()
          expect(linterProvider.lint.calls.length).toBe(1)

          atom.config.set('core.excludeVcsIgnoredPaths', true)

          linter.commands.lint()
          expect(linterProvider.lint).toHaveBeenCalled()
          expect(linterProvider.lint.calls.length).toBe(1)
