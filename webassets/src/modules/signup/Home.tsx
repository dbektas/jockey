import React, { Component } from "react";
import { Button, Table, Spinner } from "react-bootstrap";
import API from "@aws-amplify/api";
import { Redirect } from "react-router-dom";
import fullStack from "../../images/jockey-screenshot.png";
import "./home.css";

interface HomeProps {
  isAuthenticated: boolean;
}

interface HomeState {
  isLoading: boolean;
  pokemons: Pokemon[];
  redirect: boolean;
}

interface Pokemon {
  uuId: string;
  pokemon_name: string;
  pokemon_email: string;
  pokemon_type: string;
  pokemon_strength: string;
  pokemon_desc: string;
  createdAt: Date;
}

export default class Home extends Component<HomeProps, HomeState> {
  constructor(props: HomeProps) {
    super(props);

    this.state = {
      isLoading: true,
      pokemons: [],
      redirect: false,
    };
  }

  async componentDidMount() {
    if (!this.props.isAuthenticated) {
      return;
    }

    try {
      const pokemons = await this.pokemons();
      this.setState({ pokemons });
    } catch (e) {
      alert(e);
    }

    this.setState({ isLoading: false });
  }

  pokemons() {
    return API.get("pokemons", "/pokemons", null);
  }

  renderPokemonsList(pokemons: Pokemon[]) {
    let pokemonsList: Pokemon[] = [];

    return pokemonsList.concat(pokemons).map(
      (pokemon, i) =>
        <tr key={pokemon.uuId}>
          <td><a href={`/pokemon/${pokemon.uuId}`}>{pokemon.pokemon_name}</a></td>
          <td><div className="pokemon_type">{pokemon.pokemon_type.trim().split("\n")[0]}</div></td>
          <td>{new Date(pokemon.createdAt).toLocaleString()}</td>
        </tr>
    );
  }

  onCreate = () => {
    this.setState({ redirect: true });
  }

  renderLanding() {
    return (
      <div className="lander">
        <h2>Jockey</h2>
        <hr />
        <p>Jockey is an application for managing your own Pokemons. With this application users can add, update or even remove their pokemons. This application is fully serverless and runs on AWS Cloud.</p>
        <div className="button-container col-md-12">
          <a href="/signup" className="orange-link">Sign up</a>
        </div>
        <img src={fullStack} className="img-fluid full-width" alt="Screenshot"></img>
      </div>);
  }

  renderHome() {
    return (
      <div className="pokemons">
        <h1 className="text-center">Pokemons</h1>
        <div className="mb-3 float-right">
          <Button variant="primary" onClick={this.onCreate}>Add new pokemon</Button>
        </div>
        <Table variant="dark'">
          <thead>
            <tr>
              <th>Pokemon name</th>
              <th>Pokemon type</th>
              <th>Date created</th>
            </tr>
          </thead>
          <tbody>
              {
                this.state.isLoading ?
                (
                  <tr><td>
                    <Spinner animation="border" className="center-spinner" />
                  </td></tr>
                ) :
                this.renderPokemonsList(this.state.pokemons)
            }
          </tbody>
        </Table>
      </div>
    );
  }

  render() {
    let { redirect } = this.state;
    if (redirect) {
      return <Redirect push to={'/pokemon/'} />;
    }

    return (
      <div className="Home">
        {this.props.isAuthenticated ? this.renderHome() : this.renderLanding()}
      </div>
    );
  }
}
