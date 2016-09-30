import React from 'react';

// Finished slide
const Finished = React.createClass({
  propTypes: {
    currentUser: React.PropTypes.object,
    returnToParam: React.PropTypes.string
  },

  getInitialState() {
    return {};
  },

  // When this route loads, wait a second then redirect
  // out to the return_to param (or root)
  componentDidMount() {
    return this.state.timeout = setTimeout(() => {
      const returnTo = this.props.returnToParam;
      return window.location = decodeURIComponent(returnTo);
    }
    , 750);
  },

  // clear the timeout just to be safe
  componentWillUnmount() {
    return clearTimeout(this.state.timeout);
  },

  render() {
    return (
      <div className="intro">
        <h1>You´re all set. Thank you.</h1>
        <h2>Loading...</h2>
      </div>
    );
  }
});

export default Finished;
