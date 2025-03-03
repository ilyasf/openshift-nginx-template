const gulp = require('gulp');
const ts = require('gulp-typescript');
const replace = require('gulp-replace');
const tsProject = ts.createProject('tsconfig.json');
const packageJson = require('./package.json');
const version = packageJson.version;

gulp.task('scripts', function () {
  return tsProject.src()
    .pipe(tsProject())
    .pipe(replace("VERSION = 'magic'", `VERSION = '${version}'`))
    .pipe(gulp.dest('dist'));
});

gulp.task('copy-html', function () {
  return gulp.src('src/index.html')
    .pipe(gulp.dest('dist'));
});

gulp.task('copy-favicon', function () {
  return gulp.src('favicon.ico')
    .pipe(gulp.dest('dist'));
});

gulp.task('build', gulp.series('scripts', 'copy-html', 'copy-favicon'));
