const gulp = require('gulp');
const ts = require('gulp-typescript');
const replace = require('gulp-replace');
const packageJson = require('./package.json');
const version = packageJson.version;
const path = require('path');
const fs = require('fs');

function getSubdirectories(srcPath) {
  return fs.readdirSync(srcPath).filter(file => fs.statSync(path.join(srcPath, file)).isDirectory());
}

gulp.task('scripts', function(done) {
  // First handle root level TypeScript files
  const rootTask = function(taskDone) {
    const tsProject = ts.createProject('tsconfig.json');
    const stream = gulp.src('src/*.ts')
      .pipe(tsProject())
      .on('error', (err) => {
        console.error('TypeScript compilation error:', err.message);
      })
      .pipe(replace("VERSION = 'magic'", `VERSION = '${version}'`))
      .pipe(gulp.dest('dist'));
    
    stream.on('end', taskDone);
    return stream;
  };

  // Then handle subdirectory TypeScript files
  const subdirectories = getSubdirectories('src');
  const subDirTasks = subdirectories.map(subdir => {
    return function scriptsTask(taskDone) {
      const tsProject = ts.createProject('tsconfig.json');
      const package = require(`./src/${subdir}/package.json`);  
      const version = package.version;
      const stream = gulp.src(`src/${subdir}/**/*.ts`)
        .pipe(tsProject())
        .on('error', (err) => {
          console.error(`TypeScript compilation error in ${subdir}:`, err.message);
        })
        .pipe(replace("VERSION = 'magic'", `VERSION = '${version}'`))
        .pipe(gulp.dest(`dist/${subdir}`));
      
      stream.on('end', taskDone);
      return stream;
    };
  });

  return gulp.series(rootTask, ...subDirTasks)(done);
});

gulp.task('copy-html', function(done) {
  // First copy root level HTML files
  const rootTask = function(taskDone) {
    const stream = gulp.src('src/*.html')
      .pipe(gulp.dest('dist'));
    
    stream.on('end', taskDone);
    return stream;
  };

  // Then copy subdirectory HTML files
  const subdirectories = getSubdirectories('src');
  const subDirTasks = subdirectories.map(subdir => {
    return function copyHtmlTask(taskDone) {
      const stream = gulp.src(`src/${subdir}/**/*.html`)
        .pipe(gulp.dest(`dist/${subdir}`));
      
      stream.on('end', taskDone);
      return stream;
    };
  });

  return gulp.series(rootTask, ...subDirTasks)(done);
});

gulp.task('copy-favicon', function() {
  return gulp.src('favicon.ico')
    .pipe(gulp.dest('dist'));
});

gulp.task('build', gulp.series('scripts', 'copy-html', 'copy-favicon'));
