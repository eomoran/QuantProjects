from src.qp_data.schema import example_fixture, validate_dataset

def test_fixture_validates():
    df = example_fixture(5)
    validate_dataset(df)
