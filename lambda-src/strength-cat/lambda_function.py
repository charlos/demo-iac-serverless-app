import os
import boto3
from datetime import datetime
from decimal import Decimal

# Initialize DynamoDB client and table
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE_NAME']  # Replace with your DynamoDB table name
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    username = event['username']
    gender = event['gender']
    bw = float(event['bw'])
    squat = float(event['squat'])
    bench = float(event['bench'])
    deadlift = float(event['deadlift'])
    unit = event.get('unit', 'kg')  # Default to 'kg' if unit is not provided in event
    
    result = categorize_strength(gender, bw, squat, bench, deadlift, unit)
    
    # Generate current timestamp
    timestamp = datetime.now().isoformat()
    
    # Convert float values to Decimal
    bw = Decimal(str(bw))
    squat = Decimal(str(squat))
    bench = Decimal(str(bench))
    deadlift = Decimal(str(deadlift))
    
    # Convert percentages to Decimal
    squat_percentage = Decimal(str(result[0][1]))
    bench_percentage = Decimal(str(result[1][1]))
    deadlift_percentage = Decimal(str(result[2][1]))
    
    # Store the results in DynamoDB
    table.put_item(
        Item={
            'username': username,
            'timestamp': timestamp,
            'gender': gender,
            'bodyweight': bw,
            'squat': squat,
            'bench': bench,
            'deadlift': deadlift,
            'squat_category': result[0][0],
            'bench_category': result[1][0],
            'deadlift_category': result[2][0],
            'squat_percentage': squat_percentage,
            'bench_percentage': bench_percentage,
            'deadlift_percentage': deadlift_percentage
        }
    )
    
    return {
        'statusCode': 200,
        'body': {
            'Squat': result[0][0],
            'Bench': result[1][0],
            'Deadlift': result[2][0],
            'Squat_Percentage': result[0][1],
            'Bench_Percentage': result[1][1],
            'Deadlift_Percentage': result[2][1]
        }
    }

def categorize_strength(gender, bw, squat, bench, deadlift, unit='kg'):
    # Define strength standards for male and female as ranges
    standards = {
        "male": {
            "squat": [(0, 1), (1, 1.25), (1.25, 1.75), (1.75, 2.5), (2.5, 3), (3, float('inf'))],
            "bench": [(0, 0.75), (0.75, 1), (1, 1.5), (1.5, 2), (2, 2.25), (2.25, float('inf'))],
            "deadlift": [(0, 1.2), (1.2, 1.5), (1.5, 2.25), (2.25, 3), (3, 3.5), (3.5, float('inf'))]
        },
        "female": {
            "squat": [(0, 0.5), (0.5, 1), (1, 1.5), (1.5, 2.25), (1.75, 2.25), (2.25, float('inf'))],
            "bench": [(0, 0.35), (0.35, 0.5), (0.5, 0.75), (0.75, 1), (1, 1.25), (1.25, float('inf'))],
            "deadlift": [(0, 0.5), (0.5, 1), (1.25, 1.75), (1.75, 2.25), (2.25, 3), (3, float('inf'))]
        }
    }
    
    categories = ["Noob", "Beginner", "Intermediate", "Advanced", "Elite", "Freak"]
    
    # Convert kg to lbs if necessary
    if unit == 'lb':
        bw /= 2.20462
        squat /= 2.20462
        bench /= 2.20462
        deadlift /= 2.20462

    # Function to determine the category of a lift and its percentage within the category
    def determine_category_and_percentage(lift, standards, bw):
        lift_ratio = lift / bw
        for i, (low, high) in enumerate(standards):
            if low <= lift_ratio < high:
                category = categories[i]
                # Calculate the percentage within the category
                if high == float('inf'):
                    percentage_within_category = 100
                else:
                    percentage_within_category = ((lift_ratio - low) / (high - low)) * 100
                return category, percentage_within_category
        return categories[-1], 100

    # Get the appropriate standards based on gender
    gender_standards = standards[gender.lower()]
    
    # Determine categories and percentages for each lift
    squat_category, squat_percentage = determine_category_and_percentage(squat, gender_standards["squat"], bw)
    bench_category, bench_percentage = determine_category_and_percentage(bench, gender_standards["bench"], bw)
    deadlift_category, deadlift_percentage = determine_category_and_percentage(deadlift, gender_standards["deadlift"], bw)
    
    return (
        (squat_category, squat_percentage),
        (bench_category, bench_percentage),
        (deadlift_category, deadlift_percentage)
    )
