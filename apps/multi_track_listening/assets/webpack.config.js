const path = require('path');
const fs = require('fs');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

function generateDynamicEntries() {
  const entryDirPath = './js/entry';
  const entryFiles = fs.readdirSync(entryDirPath);
  return entryFiles.reduce((acc, file) => {
    const name = path.basename(file, '.js');
    const fullPath = path.resolve(entryDirPath, file);
    return Object.assign({}, acc, {
      [name]: fullPath
    });
  }, {});
}

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: generateDynamicEntries(),
  output: {
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader']
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '../css/[name].css'
    }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
  ]
});